{
  lib,
  config,
  ...
}: let
  inherit
    (lib)
    mkOption
    types
    ;

  cfg = config.services.pr-tracker;

  dbCfg = types.submodule {
    urlParams = mkOption {
      type = types.attrsOf types.str;
      description = "URL parameters from which to compose the ${builtins.readFile ../crates/DATABASE_URL.md}";
      example = {
        user = "pr-tracker";
        host = "localhost";
        port = "5432";
        dbname = "pr-tracker";
      };
    };

    passwordFile = mkOption {
      type = types.nullOr types.path;
      description = ''
        Path to a file containing the database password.
        Contents will be appended to the database URL as a parameter.
      '';
      example = "/run/secrets/db-password";
      default = null;
    };

    isLocal = mkOption {
      type = types.bool;
      description = "Whether database is local.";
      default = false;
    };
  };
in {
  options.services.pr-tracker.db = mkOption {
    type = types.either dbCfg (types.enum ["createLocally"]);
  };
  options.services.pr-tracker.dbCfg = mkOption {
    private = true;
    type = dbCfg;
  };

  config.services.pr-tracker.dbCfg = mkIf (cfg.api.enable || cfg.fetcher.enable) (
    if (cfg.db == "createLocally")
    then {
    }
    else cfg.db
  );
}
