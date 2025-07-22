{
  mkNixosModuleLib,
  moduleLocation,
  privateNixosModules,
  api,
  ...
}:
{
  flake.nixosModules.api =
    {
      lib,
      pkgs,
      config,
      options,
      ...
    }:
    let
      attrsToURLParams = import ../../attrsToURLParams.nix lib;
      nixosModuleLib = mkNixosModuleLib { inherit options config; };

      cfg = config.services.pr-tracker.api;
    in
    {
      # https://github.com/NixOS/nixpkgs/issues/215496
      key = "${moduleLocation}#api";
      _file = "${moduleLocation}#api";

      imports = [
        privateNixosModules.db
      ];

      options.services.pr-tracker.api.enable = lib.mkEnableOption "pr-tracker-api";
      options.services.pr-tracker.api.package = nixosModuleLib.mkPackageOption "api";

      options.services.pr-tracker.api.user = lib.mkOption {
        type = lib.types.str;
        description = nixosModuleLib.userDescription;
        default = "pr-tracker-api";
      };

      options.services.pr-tracker.api.group = lib.mkOption {
        type = lib.types.str;
        description = nixosModuleLib.groupDescription;
        default = "pr-tracker-api";
      };

      options.services.pr-tracker.api.port = lib.mkOption {
        type = lib.types.port;
        inherit (api.environmentVariables.PR_TRACKER_API_PORT) description;
      };

      options.services.pr-tracker.api.tracingFilter = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        inherit (api.environmentVariables.PR_TRACKER_TRACING_FILTER) description;
        default = null;
      };

      options.services.pr-tracker.api.db = nixosModuleLib.db;

      config = lib.mkIf cfg.enable {
        users.groups.${cfg.group} = { };
        users.users.${cfg.user} = {
          group = cfg.group;
          isSystemUser = true;
        };

        systemd.services.pr-tracker-api.description = "pr-tracker-api";

        systemd.services.pr-tracker-api.wantedBy = [ "multi-user.target" ];
        systemd.services.pr-tracker-api.after = [
          "network.target"
        ]
        ++ lib.optional cfg.db.isLocal "postgresql.target";
        systemd.services.pr-tracker-api.bindsTo = lib.optional cfg.db.isLocal "postgresql.target";

        systemd.services.pr-tracker-api.script = lib.concatLines (
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
        systemd.services.pr-tracker-api.serviceConfig.User = cfg.user;
        systemd.services.pr-tracker-api.serviceConfig.Group = cfg.group;
        systemd.services.pr-tracker-api.serviceConfig.Type = "notify";
        systemd.services.pr-tracker-api.serviceConfig.Restart = "always";
      };
    };
}
