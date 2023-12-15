{pr-tracker}: {
  config,
  pkgs,
  lib,
  ...
}: let
  inherit
    (lib)
    getExe
    mkEnableOption
    mkIf
    mkOption
    optional
    types
    ;

  inherit
    (builtins)
    toString
    ;

  pr-tracker-api = pr-tracker.packages.${pkgs.system}.api;
  cfg = config.services.pr-tracker-api;
in {
  options.services.pr-tracker-api.enable = mkEnableOption "the pr tracker api";

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

  options.services.pr-tracker-api.databaseUrl = mkOption {
    type = types.str;
    description = "URL of the database to connect to.";
    example = "postgresql:///pr-tracker?host=/run/postgresql?port=5432";
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
    systemd.services.pr-tracker-api.environment.ROCKET_DATABASES = "{data={url=${cfg.databaseUrl}}}";
    systemd.services.pr-tracker-api.environment.ROCKET_PORT = toString cfg.port;

    systemd.services.pr-tracker-api.wantedBy = ["multi-user.target"];
    systemd.services.pr-tracker-api.after = ["network.target"] ++ optional cfg.localDb "postgresql.service";
    systemd.services.pr-tracker-api.bindsTo = optional cfg.localDb "postgresql.service";

    systemd.services.pr-tracker-api.serviceConfig.ExecStart = getExe pr-tracker-api;
    systemd.services.pr-tracker-api.serviceConfig.User = cfg.user;
    systemd.services.pr-tracker-api.serviceConfig.Group = cfg.group;
    systemd.services.pr-tracker-api.serviceConfig.Type = "notify";
    systemd.services.pr-tracker-api.serviceConfig.Restart = "always";
  };
}
