{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  inherit
    (builtins)
    concatStringsSep
    readFile
    toJSON
    ;

  inherit
    (lib)
    escapeShellArg
    getExe
    mkEnableOption
    mkPackageOption
    mkIf
    mkOption
    types
    optional
    ;

  inherit
    (pkgs)
    urlencode
    ;

  attrsToURLParams = import ../../attrsToURLParams.nix lib;
  common = import ./common.nix {inherit lib options config;};

  cfg = config.services.pr-tracker.fetcher;
in {
  imports = [./db.nix];

  options.services.pr-tracker.fetcher.enable = mkEnableOption "pr-tracker-fetcher";
  options.services.pr-tracker.fetcher.package = mkPackageOption config._pr-tracker-packages "fetcher" {
    inherit (common) pkgsText;
  };

  options.services.pr-tracker.fetcher.user = mkOption {
    type = types.str;
    description = common.userDescription;
    default = "pr-tracker-fetcher";
  };

  options.services.pr-tracker.fetcher.group = mkOption {
    type = types.str;
    description = common.groupDescription;
    default = "pr-tracker-fetcher";
  };

  options.services.pr-tracker.fetcher.branchPatterns = mkOption {
    type = types.listOf types.str;
    description = readFile ../../crates/fetcher-config/BRANCH_PATTERNS.md;
    example = ["release-*"];
  };

  options.services.pr-tracker.fetcher.db = common.db;

  options.services.pr-tracker.fetcher.githubApiTokenFile = mkOption {
    type = types.path;
    description = "Path to a file containing a " + readFile ../../crates/fetcher-config/GITHUB_TOKEN.md;
    example = "/run/secrets/github-api.token";
  };

  options.services.pr-tracker.fetcher.repo.owner = mkOption {
    type = types.str;
    description = readFile ../../crates/fetcher-config/GITHUB_REPO_OWNER.md;
    example = "NixOS";
  };

  options.services.pr-tracker.fetcher.repo.name = mkOption {
    type = types.str;
    description = readFile ../../crates/fetcher-config/GITHUB_REPO_NAME.md;
    example = "nixpkgs";
  };

  options.services.pr-tracker.fetcher.onCalendar = mkOption {
    type = types.str;
    description = ''
      When to run the fetcher. This is a systemd timer `OnCalendar` string, see
      {manpage}`systemd.time(7)` for a full specification.";
    '';
    example = "daily";
  };

  config = mkIf cfg.enable {
    users.groups.${cfg.group} = {};
    users.users.${cfg.user} = {
      group = cfg.group;
      isSystemUser = true;
    };

    systemd.timers.pr-tracker-fetcher.timerConfig.OnCalendar = cfg.onCalendar;
    systemd.timers.pr-tracker-fetcher.wantedBy = ["timers.target"];

    systemd.services.pr-tracker-fetcher.description = "pr-tracker-fetcher";
    systemd.services.pr-tracker-fetcher.after = ["network.target"] ++ optional cfg.db.isLocal "postgresql.service";
    systemd.services.pr-tracker-fetcher.requires = optional cfg.db.isLocal "postgresql.service";
    systemd.services.pr-tracker-fetcher.script = let
      databaseUrl = "postgresql://?${attrsToURLParams cfg.db.urlParams}";

      passwordFile = optional (cfg.db.passwordFile != null) ''
        PASSWORD=$(${getExe urlencode} --encode-set component < ${cfg.db.passwordFile})
        PR_TRACKER_FETCHER_DATABASE_URL="$PR_TRACKER_FETCHER_DATABASE_URL&password=$PASSWORD"
      '';
    in
      concatStringsSep "\n" (
        [
          "export PR_TRACKER_FETCHER_DATABASE_URL=${escapeShellArg databaseUrl}"
          "export PR_TRACKER_FETCHER_GITHUB_REPO_OWNER=${escapeShellArg cfg.repo.owner}"
          "export PR_TRACKER_FETCHER_GITHUB_REPO_NAME=${escapeShellArg cfg.repo.name}"
          "export PR_TRACKER_FETCHER_BRANCH_PATTERNS=${escapeShellArg (toJSON cfg.branchPatterns)}"
          "export PR_TRACKER_FETCHER_GITHUB_TOKEN=$(< ${cfg.githubApiTokenFile})"
          # CACHE_DIRECTORY is set by systemd based on the CacheDirectory setting.
          # See https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html#RuntimeDirectory=
          "export PR_TRACKER_FETCHER_CACHE_DIR=$CACHE_DIRECTORY"
        ]
        ++ passwordFile
        ++ ["exec ${getExe cfg.package}"]
      );

    systemd.services.pr-tracker-fetcher.serviceConfig.User = cfg.user;
    systemd.services.pr-tracker-fetcher.serviceConfig.Group = cfg.group;
    systemd.services.pr-tracker-fetcher.serviceConfig.Type = "oneshot";
    systemd.services.pr-tracker-fetcher.serviceConfig.Restart = "on-failure";
    systemd.services.pr-tracker-fetcher.serviceConfig.CacheDirectory = "pr-tracker-fetcher";
  };
}
