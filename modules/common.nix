{
  lib,
  options,
  config,
}: let
  inherit
    (lib)
    mkOption
    types
    ;
in {
  userDescription = "User to run under.";
  groupDescription = "Group to run under.";

  db.urlParams = mkOption {
    type = types.nullOr (types.attrsOf types.str);
    description = ''
      URL parameters from which to compose the ${builtins.readFile ../crates/DATABASE_URL.md}
      Required unless {option}`${options.services.pr-tracker.db.createLocally}` is true.
    '';
    example = {
      user = "pr-tracker";
      host = "localhost";
      port = "5432";
      dbname = "pr-tracker";
    };
    default =
      if config.services.pr-tracker.db.createLocally
      then {
        host = "/run/postgresql";
        port = toString config.services.postgresql.settings.port;
        dbname = config.services.pr-tracker.db.name;
      }
      else null;
  };

  db.passwordFile = mkOption {
    type = types.nullOr types.path;
    description = ''
      Path to a file containing the database password.
      Contents will be appended to the database URL as a parameter.
    '';
    example = "/run/secrets/db-password";
    default = null;
  };

  db.isLocal = mkOption {
    type = types.bool;
    description = "Whether database is local.";
    default = config.services.pr-tracker.db.createLocally;
  };

  pkgsText = "pr-tracker.packages";
}
