{
  mkOption,
  types,
  ...
}: {
  userDescription = "User to run under.";
  groupDescription = "Group to run under.";

  dbUrlParams = mkOption {
    type = types.attrsOf types.str;
    description = "URL parameters from which to compose the ${builtins.readFile ../crates/DATABASE_URL.md}";
    example = {
      user = "pr-tracker";
      host = "localhost";
      port = "5432";
      dbname = "pr-tracker";
    };
  };

  dbPasswordFile = mkOption {
    type = types.nullOr types.path;
    description = ''
      Path to a file containing the database password.
      Contents will be appended to the database URL as a parameter.
    '';
    example = "/run/secrets/db-password";
    default = null;
  };

  localDb = mkOption {
    type = types.bool;
    description = "Whether database is local.";
    default = false;
  };

  pkgsText = "pr-tracker.packages";
}
