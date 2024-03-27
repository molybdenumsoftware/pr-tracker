{
  user = "User to run under.";
  group = "Group to run under.";
  db.user = "Database user.";
  db.urlParams = "URL parameters from which to compose the ${builtins.readFile ../crates/DATABASE_URL.md}";
  db.passwordFile = ''
    Path to a file containing the database password.
    Contents will be appended to the database URL as a parameter.
  '';
  db.isLocal = "Whether database is local.";
  pkgsText = "pr-tracker.packages";
}
