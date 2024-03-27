{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit
    (lib)
    concatStringsSep
    escapeShellArg
    filterAttrs
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
    readFile
    toString
    ;

  inherit
    (pkgs)
    urlencode
    ;

  attrsToURLParams = import ../attrsToURLParams.nix lib;
  common = import ./common.nix;

  cfg = config.services.pr-tracker.api;
in {
  options.services.pr-tracker.api.enable = mkEnableOption "pr-tracker-api";
  options.services.pr-tracker.api.package = mkPackageOption config._pr-tracker-packages "api" {
    inherit (common) pkgsText;
  };

  options.services.pr-tracker.api.user = mkOption {
    type = types.str;
    description = common.user;
    default = "pr-tracker-api";
  };

  options.services.pr-tracker.api.group = mkOption {
    type = types.str;
    description = common.group;
    default = "pr-tracker-api";
  };

  options.services.pr-tracker.api.port = mkOption {
    type = types.port;
    description = readFile ../crates/api-config/PORT.md;
  };

  options.services.pr-tracker.api.db.user = mkOption {
    type = types.nullOr types.str;
    description = common.db.user;
    example = "pr-tracker-api";
    default = null;
  };

  options.services.pr-tracker.api.db.urlParams = mkOption {
    type = types.attrsOf types.str;
    description = common.db.urlParams;
    example = {
      host = "localhost";
      port = "5432";
      dbname = "pr-tracker";
    };
  };

  options.services.pr-tracker.api.db.passwordFile = mkOption {
    type = types.nullOr types.path;
    description = common.db.passwordFile;
    example = "/run/secrets/db-password";
    default = null;
  };

  options.services.pr-tracker.api.db.isLocal = mkOption {
    type = types.bool;
    description = common.db.isLocal;
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
    systemd.services.pr-tracker-api.after = ["network.target"] ++ optional cfg.db.isLocal "postgresql.service";
    systemd.services.pr-tracker-api.bindsTo = optional cfg.db.isLocal "postgresql.service";

    systemd.services.pr-tracker-api.script = let
      userParam = filterAttrs (_: v: v != null) {inherit (cfg.db) user;};
      urlParams = userParam // cfg.db.urlParams;
      databaseUrl = "postgresql://?${attrsToURLParams urlParams}";

      passwordFile = optional (cfg.db.passwordFile != null) ''
        PASSWORD=$(${getExe urlencode} --encode-set component < ${cfg.db.passwordFile})
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
