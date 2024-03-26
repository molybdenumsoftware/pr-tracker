{
  lib,
  config,
  ...
}: let
  inherit
    (lib)
    mkIf
    mkOption
    types
    ;

  cfg = config.services.pr-tracker;

  dbCfgType = types.submodule {
    options = {
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

      createLocally = mkOption {
        type = types.nullOr types.bool;
        description = "Whether to create a local database automatically.";
        default = false;
      };
    };
  };
in {
  options.services.pr-tracker.db = mkOption {
    type = types.either dbCfgType (types.enum ["createLocally"]);
    description = "";
  };

  options.services.pr-tracker.dbCfg = mkOption {
    #internal = true;
    description = "";
    type = dbCfgType;
  };

  config.services.pr-tracker.dbCfg = mkIf ((cfg.api or {}).enable or false || (cfg.fetcher or {}).enable or false) (
    if (cfg.db == "createLocally")
    then {
      urlParams = {
        host = "/run/postgresql";
        port = toString config.services.postgresql.port;
        dbname = "pr-tracker";
      };
      isLocal = true;
    }
    else cfg.db
  );
}
