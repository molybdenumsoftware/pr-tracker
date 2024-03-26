{lib, ...}: let
  inherit
    (lib)
    mkOption
    types
    ;
in {
  options.services.pr-tracker.db = {
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
}
