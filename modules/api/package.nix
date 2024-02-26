{
  pr-tracker,
  attrsToURLParams,
}: {
  lib,
  pkgs,
  config,
  ...
}: let
  inherit
    (lib)
    concatStringsSep
    escapeShellArg
    getExe
    mkEnableOption
    mkPackageOption
    mkIf
    mkOption
    optional
    types
    ;

  inherit
    (builtins)
    toString
    ;

  inherit
    (pkgs)
    system
    urlencode
    ;

  cfg = config.services.pr-tracker-api;
in {
  options.services.pr-tracker-api.enable = mkEnableOption "pr-tracker-api";
  options.services.pr-tracker-api.package = mkPackageOption pr-tracker.packages.${system} "api" {};

  options.services.pr-tracker-api.user = mkOption {
    type = types.str;
    description = "User to run under.";
    default = "pr-tracker-api";
  };

  options.services.pr-tracker-api.group = mkOption {
    type = types.str;
    description = "Group to run under.";
    default = "pr-tracker-api";
  };

  options.services.pr-tracker-api.port = mkOption {
    type = types.port;
    description = "Port to listen on.";
  };

  options.services.pr-tracker-api.dbUrlParams = mkOption {
    type = types.attrsOf types.str;
    description = "URL parameters to compose the database URL from.";
    example = {
      user = "pr-tracker";
      host = "localhost";
      port = "5432";
      dbname = "pr-tracker";
    };
  };

  options.services.pr-tracker-api.dbPasswordFile = mkOption {
    type = types.nullOr types.path;
    description = "Path to a file containing the database password.";
    example = "/run/secrets/db-password";
    default = null;
  };

  options.services.pr-tracker-api.localDb = mkOption {
    type = types.bool;
    description = "Whether database is local.";
    default = false;
  };

  config = mkIf cfg.enable {
    users.groups.${cfg.group} = {};
    users.users.${cfg.user} = {
      group = cfg.group;
      isSystemUser = true;
    };

    systemd.services.pr-tracker-api.description = "pr-tracker-api";

    systemd.services.pr-tracker-api.wantedBy = ["multi-user.target"];
    systemd.services.pr-tracker-api.after = ["network.target"] ++ optional cfg.localDb "postgresql.service";
    systemd.services.pr-tracker-api.bindsTo = optional cfg.localDb "postgresql.service";

    systemd.services.pr-tracker-api.script = let
      databaseUrl = "postgresql://?${attrsToURLParams cfg.dbUrlParams}";

      passwordFile = optional (cfg.dbPasswordFile != null) ''
        PASSWORD=$(${getExe urlencode} --encode-set component < ${cfg.dbPasswordFile})
        PR_TRACKER_API_DATABASE_URL="$PR_TRACKER_API_DATABASE_URL&password=$PASSWORD"
      '';
    in
      concatStringsSep "\n" (
        [
          "export PR_TRACKER_API_DATABASE_URL=${escapeShellArg databaseUrl}"
          "export PR_TRACKER_API_PORT=${escapeShellArg (toString cfg.port)}"
        ]
        ++ passwordFile
        ++ ["exec ${getExe cfg.package}"]
      );
    systemd.services.pr-tracker-api.serviceConfig.User = cfg.user;
    systemd.services.pr-tracker-api.serviceConfig.Group = cfg.group;
    systemd.services.pr-tracker-api.serviceConfig.Type = "notify";
    systemd.services.pr-tracker-api.serviceConfig.Restart = "always";
  };
}
