{
  mkNixosModuleLib,
  moduleLocation,
  privateNixosModules,
  fetcher,
  ...
}:
{
  flake.nixosModules.fetcher =
    {
      config,
      lib,
      options,
      pkgs,
      ...
    }:
    let
      attrsToURLParams = import ../../attrsToURLParams.nix lib;
      nixosModuleLib = mkNixosModuleLib { inherit options config; };

      cfg = config.services.pr-tracker.fetcher;
    in
    {
      # https://github.com/NixOS/nixpkgs/issues/215496
      key = "${moduleLocation}#fetcher";
      _file = "${moduleLocation}#fetcher";

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
        inherit (fetcher.environmentVariables.PR_TRACKER_FETCHER_BRANCH_PATTERNS) description;
        example = [ "release-*" ];
      };

      options.services.pr-tracker.fetcher.db = nixosModuleLib.db;

      options.services.pr-tracker.fetcher.githubApiTokenFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to a file containing a ${fetcher.environmentVariables.PR_TRACKER_FETCHER_GITHUB_TOKEN.description}";
        example = "/run/secrets/github-api.token";
      };

      options.services.pr-tracker.fetcher.repo.owner = lib.mkOption {
        type = lib.types.str;
        inherit (fetcher.environmentVariables.PR_TRACKER_FETCHER_GITHUB_REPO_OWNER) description;
        example = "NixOS";
      };

      options.services.pr-tracker.fetcher.repo.name = lib.mkOption {
        type = lib.types.str;
        inherit (fetcher.environmentVariables.PR_TRACKER_FETCHER_GITHUB_REPO_NAME) description;
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
        users.groups.${cfg.group} = { };
        users.users.${cfg.user} = {
          group = cfg.group;
          isSystemUser = true;
        };

        systemd.timers.pr-tracker-fetcher.timerConfig.OnCalendar = cfg.onCalendar;
        systemd.timers.pr-tracker-fetcher.wantedBy = [ "timers.target" ];

        systemd.services.pr-tracker-fetcher.description = "pr-tracker-fetcher";
        systemd.services.pr-tracker-fetcher.after = [
          "network.target"
        ]
        ++ lib.optional cfg.db.isLocal "postgresql.target";
        systemd.services.pr-tracker-fetcher.requires = lib.optional cfg.db.isLocal "postgresql.target";
        systemd.services.pr-tracker-fetcher.script = lib.concatLines (
          [
            "export ${fetcher.environmentVariables.PR_TRACKER_FETCHER_DATABASE_URL.name}=${lib.escapeShellArg "postgresql://?${attrsToURLParams cfg.db.urlParams}"}"
            "export ${fetcher.environmentVariables.PR_TRACKER_FETCHER_GITHUB_REPO_OWNER.name}=${lib.escapeShellArg cfg.repo.owner}"
            "export ${fetcher.environmentVariables.PR_TRACKER_FETCHER_GITHUB_REPO_NAME.name}=${lib.escapeShellArg cfg.repo.name}"
            "export ${fetcher.environmentVariables.PR_TRACKER_FETCHER_BRANCH_PATTERNS.name}=${lib.escapeShellArg (builtins.toJSON cfg.branchPatterns)}"
            "export ${fetcher.environmentVariables.PR_TRACKER_FETCHER_GITHUB_TOKEN.name}=$(< ${cfg.githubApiTokenFile})"
            # CACHE_DIRECTORY is set by systemd based on the CacheDirectory setting.
            # See https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html#RuntimeDirectory=
            "export ${fetcher.environmentVariables.PR_TRACKER_FETCHER_CACHE_DIR.name}=$CACHE_DIRECTORY"
          ]
          ++ lib.optional (cfg.db.passwordFile != null) ''
            PASSWORD=$(${lib.getExe pkgs.urlencode} --encode-set component < ${cfg.db.passwordFile})
            ${fetcher.environmentVariables.PR_TRACKER_FETCHER_DATABASE_URL.name}+="&password=$PASSWORD"
          ''
          ++ [ "exec ${lib.getExe cfg.package}" ]
        );

        systemd.services.pr-tracker-fetcher.serviceConfig.User = cfg.user;
        systemd.services.pr-tracker-fetcher.serviceConfig.Group = cfg.group;
        systemd.services.pr-tracker-fetcher.serviceConfig.Type = "oneshot";
        systemd.services.pr-tracker-fetcher.serviceConfig.Restart = "on-failure";
        systemd.services.pr-tracker-fetcher.serviceConfig.CacheDirectory = "pr-tracker-fetcher";
      };
    };
}
