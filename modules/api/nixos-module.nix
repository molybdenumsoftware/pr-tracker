{
  mkNixosModuleLib,
  moduleLocation,
  privateNixosModules,
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
        description = builtins.readFile ../../crates/api-config/PORT.md;
      };

      options.services.pr-tracker.api.tracingFilter = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        description = builtins.readFile ../../crates/api-config/TRACING_FILTER.md;
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
        ] ++ lib.optional cfg.db.isLocal "postgresql.service";
        systemd.services.pr-tracker-api.bindsTo = lib.optional cfg.db.isLocal "postgresql.service";

        systemd.services.pr-tracker-api.script = lib.concatStringsSep "\n" (
          [
            "export PR_TRACKER_API_DATABASE_URL=${lib.escapeShellArg "postgresql://?${attrsToURLParams cfg.db.urlParams}"}"
            "export PR_TRACKER_API_PORT=${lib.escapeShellArg (toString cfg.port)}"
          ]
          ++ (lib.optional (
            cfg.tracingFilter != null
          ) "export PR_TRACKER_TRACING_FILTER=${lib.escapeShellArg cfg.tracingFilter}")
          ++ lib.optional (cfg.db.passwordFile != null) ''
            PASSWORD=$(${lib.getExe pkgs.urlencode} --encode-set component < ${cfg.db.passwordFile})
            PR_TRACKER_API_DATABASE_URL="$PR_TRACKER_API_DATABASE_URL&password=$PASSWORD"
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
