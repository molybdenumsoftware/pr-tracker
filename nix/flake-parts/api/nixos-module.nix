{
  mkNixosModuleLib,
  moduleLocation,
  privateNixosModules,
  api,
  lib,
  config,
  ...
}:
{
  flake.nixosModules.api =
    nixosArgs@{ pkgs, ... }:
    let
      attrsToURLParams = import (config.projectRoot + "/nix/attrsToURLParams.nix") lib;
      nixosModuleLib = mkNixosModuleLib {
        inherit (nixosArgs) options config;
      };

      cfg = nixosArgs.config.services.pr-tracker.api;
    in
    {
      # https://github.com/NixOS/nixpkgs/issues/215496
      key = "${moduleLocation}#api";
      _file = "${moduleLocation}#api";

      imports = [ privateNixosModules.db ];

      options.services.pr-tracker.api = {
        enable = lib.mkEnableOption "pr-tracker-api";
        package = lib.mkPackageOption pkgs "pr-tracker-api" { };

        user = lib.mkOption {
          type = lib.types.str;
          description = "User to run under.";
          default = "pr-tracker-api";
        };

        group = lib.mkOption {
          type = lib.types.str;
          description = "Group to run under.";
          default = "pr-tracker-api";
        };

        port = lib.mkOption {
          type = lib.types.port;
          inherit (api.environmentVariables.PR_TRACKER_API_PORT) description;
        };

        tracingFilter = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          inherit (api.environmentVariables.PR_TRACKER_TRACING_FILTER) description;
          default = null;
        };

        inherit (nixosModuleLib) db;
      };

      config = lib.mkIf cfg.enable {
        users =

          {
            groups.${cfg.group} = { };
            users.${cfg.user} = {
              inherit (cfg) group;
              isSystemUser = true;
            };

          };

        systemd.services.pr-tracker-api = {
          description = "pr-tracker-api";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ] ++ lib.optional cfg.db.isLocal "postgresql.target";
          bindsTo = lib.optional cfg.db.isLocal "postgresql.target";

          script = lib.concatLines (
            [
              "export ${api.environmentVariables.PR_TRACKER_API_DATABASE_URL.name}=${lib.escapeShellArg "postgresql://?${attrsToURLParams cfg.db.urlParams}"}"
              "export ${api.environmentVariables.PR_TRACKER_API_PORT.name}=${lib.escapeShellArg (toString cfg.port)}"
            ]
            ++ (lib.optional (cfg.tracingFilter != null)
              "export ${api.environmentVariables.PR_TRACKER_TRACING_FILTER.name}=${lib.escapeShellArg cfg.tracingFilter}"
            )
            ++ lib.optional (cfg.db.passwordFile != null) ''
              PASSWORD=$(${lib.getExe pkgs.urlencode} --encode-set component < ${cfg.db.passwordFile})
              ${api.environmentVariables.PR_TRACKER_API_DATABASE_URL.name}+="&password=$PASSWORD"
            ''
            ++ [ "exec ${lib.getExe cfg.package}" ]
          );

          serviceConfig = {
            User = cfg.user;
            Group = cfg.group;
            Type = "notify";
            Restart = "always";
          };
        };
      };
    };
}
