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
  common = import ./common.nix;

  cfg = config.services.pr-tracker.api;
  dbCfg = config.services.pr-tracker.db;
in {
  imports = [./db.nix];

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

  config = mkIf cfg.enable {
    users.groups.${cfg.group} = {};
    users.users.${cfg.user} = {
      group = cfg.group;
      isSystemUser = true;
    };

    systemd.services.pr-tracker-api.description = "pr-tracker-api";

    systemd.services.pr-tracker-api.wantedBy = ["multi-user.target"];
    systemd.services.pr-tracker-api.after = ["network.target"] ++ optional dbCfg.isLocal "postgresql.service";
    systemd.services.pr-tracker-api.bindsTo = optional dbCfg.isLocal "postgresql.service";

    systemd.services.pr-tracker-api.script = let
      databaseUrl = "postgresql://?${attrsToURLParams dbCfg.urlParams}";

      passwordFile = optional (dbCfg.passwordFile != null) ''
        PASSWORD=$(${getExe urlencode} --encode-set component < ${dbCfg.passwordFile})
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
