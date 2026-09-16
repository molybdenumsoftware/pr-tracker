{
  moduleLocation,
  privateNixosModules,
  lib,
  config,
  ...
}:
{
  flake.nixosModules.fetcher =
    nixosArgs@{ pkgs, ... }:
    let
      attrsToURLParams = import (config.projectRoot + "/nix/attrsToURLParams.nix") lib;

      cfg = nixosArgs.config.services.pr-tracker.fetcher;
    in
    {
      # https://github.com/NixOS/nixpkgs/issues/215496
      key = "${moduleLocation}#fetcher";
      _file = "${moduleLocation}#fetcher";

      imports = [ privateNixosModules.db ];

      options.services.pr-tracker.fetcher = {
        enable = lib.mkEnableOption "pr-tracker-fetcher";
        package = lib.mkPackageOption pkgs "pr-tracker-fetcher" { };

        user = lib.mkOption {
          type = lib.types.str;
          description = "User to run under.";
          default = "pr-tracker-fetcher";
        };

        group = lib.mkOption {
          type = lib.types.str;
          description = "Group to run under.";
          default = "pr-tracker-fetcher";
        };

        branchPatterns = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          inherit (cfg.package.passthru.configVars.fetcher.PR_TRACKER_FETCHER_BRANCH_PATTERNS) description;
          example = [ "release-*" ];
        };

        db = nixosArgs.config.services.pr-tracker.db.clientOptions;

        githubApiTokenFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to a file containing a ${cfg.package.passthru.configVars.fetcher.PR_TRACKER_FETCHER_GITHUB_TOKEN.description}";
          example = "/run/secrets/github-api.token";
        };

        repo.owner = lib.mkOption {
          type = lib.types.str;
          inherit (cfg.package.passthru.configVars.fetcher.PR_TRACKER_FETCHER_GITHUB_REPO_OWNER) description;
          example = "NixOS";
        };

        repo.name = lib.mkOption {
          type = lib.types.str;
          inherit (cfg.package.passthru.configVars.fetcher.PR_TRACKER_FETCHER_GITHUB_REPO_NAME) description;
          example = "nixpkgs";
        };

        onCalendar = lib.mkOption {
          type = lib.types.str;
          description = ''
            When to run the fetcher. This is a systemd timer `OnCalendar` string, see
            {manpage}`systemd.time(7)` for a full specification.";
          '';
          example = "daily";
        };
      };

      config = lib.mkIf cfg.enable {
        users = {

          groups.${cfg.group} = { };
          users.${cfg.user} = {
            inherit (cfg) group;
            isSystemUser = true;
          };
        };

        systemd = {
          timers.pr-tracker-fetcher = {
            timerConfig.OnCalendar = cfg.onCalendar;
            wantedBy = [ "timers.target" ];
          };
          services.pr-tracker-fetcher = {
            description = "pr-tracker-fetcher";
            after = [
              "network.target"
            ]
            ++ lib.optional cfg.db.isLocal "postgresql.target";
            requires = lib.optional cfg.db.isLocal "postgresql.target";
            script = lib.concatLines (
              [
                "export ${cfg.package.passthru.configVars.fetcher.PR_TRACKER_FETCHER_DATABASE_URL.name}=${lib.escapeShellArg "postgresql://?${attrsToURLParams cfg.db.urlParams}"}"
                "export ${cfg.package.passthru.configVars.fetcher.PR_TRACKER_FETCHER_GITHUB_REPO_OWNER.name}=${lib.escapeShellArg cfg.repo.owner}"
                "export ${cfg.package.passthru.configVars.fetcher.PR_TRACKER_FETCHER_GITHUB_REPO_NAME.name}=${lib.escapeShellArg cfg.repo.name}"
                "export ${cfg.package.passthru.configVars.fetcher.PR_TRACKER_FETCHER_BRANCH_PATTERNS.name}=${lib.escapeShellArg (builtins.toJSON cfg.branchPatterns)}"
                "export ${cfg.package.passthru.configVars.fetcher.PR_TRACKER_FETCHER_GITHUB_TOKEN.name}=$(< ${cfg.githubApiTokenFile})"
                # CACHE_DIRECTORY is set by systemd based on the CacheDirectory setting.
                # See https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html#RuntimeDirectory=
                "export ${cfg.package.passthru.configVars.fetcher.PR_TRACKER_FETCHER_CACHE_DIR.name}=$CACHE_DIRECTORY"
              ]
              ++ lib.optional (cfg.db.passwordFile != null) ''
                PASSWORD=$(${lib.getExe pkgs.urlencode} --encode-set component < ${cfg.db.passwordFile})
                ${cfg.package.passthru.configVars.fetcher.PR_TRACKER_FETCHER_DATABASE_URL.name}+="&password=$PASSWORD"
              ''
              ++ [ "exec ${lib.getExe cfg.package}" ]
            );

            serviceConfig = {
              User = cfg.user;
              Group = cfg.group;
              Type = "oneshot";
              Restart = "on-failure";
              CacheDirectory = "pr-tracker-fetcher";
            };
          };
        };

      };
    };
}
