{
  user = "User to run under.";
  group = "Group to run under.";
  dbUrlParams = "URL parameters from which to compose the ${builtins.readFile ../crates/DATABASE_URL.md}";
  dbPasswordFile = ''
    Path to a file containing the database password.
    Contents will be appended to the database URL as a parameter.
  '';
  localDb = "Whether database is local.";
  pkgsText = "pr-tracker.packages";
}
