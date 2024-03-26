{
  lib,
  config,
  ...
}: let
  inherit
    (lib)
    mkIf
    mkOption
    optional
    types
    ;

  cfg = config.services.pr-tracker;
  programsEnabled = (cfg.api or {}).enable or false || (cfg.fetcher or {}).enable or false;
  dbname = "pr-tracker";
in {
  options.services.pr-tracker.db.urlParams = mkOption {
    type = types.attrsOf types.str;
    description = "URL parameters from which to compose the ${builtins.readFile ../crates/DATABASE_URL.md}";
    example = {
      user = "pr-tracker";
      host = "localhost";
      port = "5432";
      dbname = "pr-tracker";
    };
  };

  options.services.pr-tracker.db.passwordFile = mkOption {
    type = types.nullOr types.path;
    description = ''
      Path to a file containing the database password.
      Contents will be appended to the database URL as a parameter.
    '';
    example = "/run/secrets/db-password";
    default = null;
  };

  options.services.pr-tracker.db.isLocal = mkOption {
    type = types.bool;
    description = "Whether database is local.";
    default = false;
  };

  options.services.pr-tracker.db.createLocally = mkOption {
    type = types.nullOr types.bool;
    description = "Whether to create a local database automatically.";
    default = false;
  };

  config.services.pr-tracker.db.urlParams = mkIf (programsEnabled && cfg.db.createLocally) {
    host = "/run/postgresql";
    port = toString config.services.postgresql.port;
    inherit dbname;
  };

  config.services.pr-tracker.db.isLocal = mkIf (programsEnabled && cfg.db.createLocally) true;

  config.services.postgresql = mkIf (programsEnabled && cfg.db.createLocally) {
    enable = true;
    ensureDatabases = [dbname];
    ensureUsers =
      (
        optional (cfg ? api)
        {
          name = cfg.api.user;
          ensureDBOwnership = true;
        }
      )
      ++ (
        optional (cfg ? fetcher)
        {
          name = cfg.fetcher.user;
          ensureDBOwnership = true;
        }
      );
  };
}
