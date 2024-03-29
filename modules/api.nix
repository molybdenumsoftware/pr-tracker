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
  common = import ./common.nix lib;

  cfg = config.services.pr-tracker.api;
in {
  options.services.pr-tracker.api.enable = mkEnableOption "pr-tracker-api";
  options.services.pr-tracker.api.package = mkPackageOption config._pr-tracker-packages "api" {
    inherit (common) pkgsText;
  };

  options.services.pr-tracker.api.user = mkOption {
    type = types.str;
    description = common.userDescription;
    default = "pr-tracker-api";
  };

  options.services.pr-tracker.api.group = mkOption {
    type = types.str;
    description = common.groupDescription;
    default = "pr-tracker-api";
  };

  options.services.pr-tracker.api.port = mkOption {
    type = types.port;
    description = readFile ../crates/api-config/PORT.md;
  };

  options.services.pr-tracker.api.dbUrlParams = common.dbUrlParams;
  options.services.pr-tracker.api.dbPasswordFile = common.dbPasswordFile;
  options.services.pr-tracker.api.localDb = common.localDb;

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
