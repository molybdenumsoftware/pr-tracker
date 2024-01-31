{pr-tracker}: {
  config,
  lib,
  pkgs,
  ...
}: let
  inherit
    (builtins)
    toJSON
    ;

  inherit
    (lib)
    getExe
    mkEnableOption
    mkPackageOption
    mkIf
    mkOption
    types
    optional
    ;

  cfg = config.services.pr-tracker-fetcher;
in {
  options.services.pr-tracker-fetcher.enable = mkEnableOption "the pr tracker fetcher";
  options.services.pr-tracker-fetcher.package = mkPackageOption pr-tracker.packages.${pkgs.system} "fetcher" {};

  options.services.pr-tracker-fetcher.user = mkOption {
    type = types.str;
    description = "User to run under.";
    default = "pr-tracker-fetcher";
  };

  options.services.pr-tracker-fetcher.group = mkOption {
    type = types.str;
    description = "Group to run under.";
    default = "pr-tracker-fetcher";
  };

  options.services.pr-tracker-fetcher.branchPatterns = mkOption {
    type = types.listOf types.str;
    description = "List of branch patterns to track.";
    example = ["release-*"];
  };

  options.services.pr-tracker-fetcher.databaseUrl = mkOption {
    type = types.str;
    description = "URL of the database to connect to.";
    example = "postgresql:///pr-tracker?host=/run/postgresql?port=5432";
  };

  options.services.pr-tracker-fetcher.localDb = mkOption {
    type = types.bool;
    description = "Whether database is local.";
    default = false;
  };

  options.services.pr-tracker-fetcher.githubApiTokenFile = mkOption {
    type = types.path;
    description = "Path to a file containing a GitHub API token.";
    example = "/run/secrets/github-api.token";
  };

  options.services.pr-tracker-fetcher.cacheDir = mkOption {
    type = types.path;
    description = "Cache directory";
    default = "/var/cache/pr-tracker-fetcher";
  };

  options.services.pr-tracker-fetcher.repo.owner = mkOption {
    type = types.str;
    description = "Owner of the GitHub repository to track.";
    example = "NixOS";
  };

  options.services.pr-tracker-fetcher.repo.name = mkOption {
    type = types.str;
    description = "Name of the GitHub repository to track.";
    example = "nixpkgs";
  };

  options.services.pr-tracker-fetcher.onCalendar = mkOption {
    type = types.str;
    description = lib.mdDoc ''
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
    systemd.services.pr-tracker-fetcher.environment.PR_TRACKER_FETCHER_DATABASE_URL = cfg.databaseUrl;
    systemd.services.pr-tracker-fetcher.environment.PR_TRACKER_FETCHER_GITHUB_REPO_OWNER = cfg.repo.owner;
    systemd.services.pr-tracker-fetcher.environment.PR_TRACKER_FETCHER_GITHUB_REPO_NAME = cfg.repo.name;
    systemd.services.pr-tracker-fetcher.environment.PR_TRACKER_FETCHER_CACHE_DIR = cfg.cacheDir;
    systemd.services.pr-tracker-fetcher.environment.PR_TRACKER_FETCHER_BRANCH_PATTERNS = toJSON cfg.branchPatterns;
    systemd.services.pr-tracker-fetcher.after = ["network.target"] ++ optional cfg.localDb "postgresql.service";
    systemd.services.pr-tracker-fetcher.requires = optional cfg.localDb "postgresql.service";
    systemd.services.pr-tracker-fetcher.script = ''
      export PR_TRACKER_FETCHER_GITHUB_TOKEN=$(< ${cfg.githubApiTokenFile})
      exec ${getExe cfg.package}
    '';

    systemd.services.pr-tracker-fetcher.serviceConfig.User = cfg.user;
    systemd.services.pr-tracker-fetcher.serviceConfig.Group = cfg.group;
    systemd.services.pr-tracker-fetcher.serviceConfig.Type = "oneshot";
    systemd.services.pr-tracker-fetcher.serviceConfig.Restart = "on-failure";
  };
}
