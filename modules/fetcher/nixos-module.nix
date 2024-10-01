{
  mkNixosModuleLib,
  privateNixosModules,
  ...
}: {
  flake.nixosModules.fetcher = {
    config,
    lib,
    options,
    pkgs,
    ...
  }: let
    attrsToURLParams = import ../../attrsToURLParams.nix lib;
    nixosModuleLib = mkNixosModuleLib {inherit options config;};

    cfg = config.services.pr-tracker.fetcher;
  in {
    imports = [
      privateNixosModules.db
    ];

    options.services.pr-tracker.fetcher.enable = lib.mkEnableOption "pr-tracker-fetcher";
    options.services.pr-tracker.fetcher.package = nixosModuleLib.mkPackageOption "fetcher";

    options.services.pr-tracker.fetcher.user = lib.mkOption {
      type = lib.types.str;
      description = nixosModuleLib.userDescription;
      default = "pr-tracker-fetcher";
    };

    options.services.pr-tracker.fetcher.group = lib.mkOption {
      type = lib.types.str;
      description = nixosModuleLib.groupDescription;
      default = "pr-tracker-fetcher";
    };

    options.services.pr-tracker.fetcher.branchPatterns = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = builtins.readFile ../../crates/fetcher-config/BRANCH_PATTERNS.md;
      example = ["release-*"];
    };

    options.services.pr-tracker.fetcher.db = nixosModuleLib.db;

    options.services.pr-tracker.fetcher.githubApiTokenFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to a file containing a " + builtins.readFile ../../crates/fetcher-config/GITHUB_TOKEN.md;
      example = "/run/secrets/github-api.token";
    };

    options.services.pr-tracker.fetcher.repo.owner = lib.mkOption {
      type = lib.types.str;
      description = builtins.readFile ../../crates/fetcher-config/GITHUB_REPO_OWNER.md;
      example = "NixOS";
    };

    options.services.pr-tracker.fetcher.repo.name = lib.mkOption {
      type = lib.types.str;
      description = builtins.readFile ../../crates/fetcher-config/GITHUB_REPO_NAME.md;
      example = "nixpkgs";
    };

    options.services.pr-tracker.fetcher.onCalendar = lib.mkOption {
      type = lib.types.str;
      description = ''
        When to run the fetcher. This is a systemd timer `OnCalendar` string, see
        {manpage}`systemd.time(7)` for a full specification.";
      '';
      example = "daily";
    };

    config = lib.mkIf cfg.enable {
      users.groups.${cfg.group} = {};
      users.users.${cfg.user} = {
        group = cfg.group;
        isSystemUser = true;
      };

      systemd.timers.pr-tracker-fetcher.timerConfig.OnCalendar = cfg.onCalendar;
      systemd.timers.pr-tracker-fetcher.wantedBy = ["timers.target"];

      systemd.services.pr-tracker-fetcher.description = "pr-tracker-fetcher";
      systemd.services.pr-tracker-fetcher.after = ["network.target"] ++ lib.optional cfg.db.isLocal "postgresql.service";
      systemd.services.pr-tracker-fetcher.requires = lib.optional cfg.db.isLocal "postgresql.service";
      systemd.services.pr-tracker-fetcher.script = let
        databaseUrl = "postgresql://?${attrsToURLParams cfg.db.urlParams}";

        passwordFile = lib.optional (cfg.db.passwordFile != null) ''
          PASSWORD=$(${lib.getExe pkgs.urlencode} --encode-set component < ${cfg.db.passwordFile})
          PR_TRACKER_FETCHER_DATABASE_URL="$PR_TRACKER_FETCHER_DATABASE_URL&password=$PASSWORD"
        '';
      in
        builtins.concatStringsSep "\n" (
          [
            "export PR_TRACKER_FETCHER_DATABASE_URL=${lib.escapeShellArg databaseUrl}"
            "export PR_TRACKER_FETCHER_GITHUB_REPO_OWNER=${lib.escapeShellArg cfg.repo.owner}"
            "export PR_TRACKER_FETCHER_GITHUB_REPO_NAME=${lib.escapeShellArg cfg.repo.name}"
            "export PR_TRACKER_FETCHER_BRANCH_PATTERNS=${lib.escapeShellArg (builtins.toJSON cfg.branchPatterns)}"
            "export PR_TRACKER_FETCHER_GITHUB_TOKEN=$(< ${cfg.githubApiTokenFile})"
            # CACHE_DIRECTORY is set by systemd based on the CacheDirectory setting.
            # See https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html#RuntimeDirectory=
            "export PR_TRACKER_FETCHER_CACHE_DIR=$CACHE_DIRECTORY"
          ]
          ++ passwordFile
          ++ ["exec ${lib.getExe cfg.package}"]
        );

      systemd.services.pr-tracker-fetcher.serviceConfig.User = cfg.user;
      systemd.services.pr-tracker-fetcher.serviceConfig.Group = cfg.group;
      systemd.services.pr-tracker-fetcher.serviceConfig.Type = "oneshot";
      systemd.services.pr-tracker-fetcher.serviceConfig.Restart = "on-failure";
      systemd.services.pr-tracker-fetcher.serviceConfig.CacheDirectory = "pr-tracker-fetcher";
    };
  };
}
