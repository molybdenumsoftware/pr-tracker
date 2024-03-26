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
  programsEnabled = (cfg.api or {}).enable or false || (cfg.fetcher or {}).enable or false;
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

  config.services.pr-tracker.db.urlParams = mkIf programsEnabled (
    if cfg.db.createLocally
    then {
      urlParams.host = "/run/postgresql";
      urlParams.port = toString config.services.postgresql.port;
      urlParams.dbname = "pr-tracker";
      isLocal = true;
      createLocally = true;
    }
    else cfg.db
  );
}
