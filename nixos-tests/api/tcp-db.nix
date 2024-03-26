pr-tracker: {
  pkgs,
  config,
  ...
}: let
  inherit
    (pkgs)
    system
    writeText
    ;
  dbPass = "api-db-secret";
  port = 7000;
  pgPort = 5432;
  user = "pr-tracker";
in {
  imports = [pr-tracker.nixosModules.api];

  nixpkgs.hostPlatform = system;

  services.postgresql.enable = true;
  services.postgresql.port = pgPort;
  services.postgresql.enableTCPIP = true;
  services.postgresql.initialScript = writeText "postgresql-init-script" ''
    CREATE ROLE "${user}" WITH LOGIN PASSWORD '${dbPass}';
  '';
  services.postgresql.authentication =
    # type   database  user  address    auth-method
    ''
      host   all       all   0.0.0.0/0  md5
    '';
  services.postgresql.ensureDatabases = [user];
  services.postgresql.ensureUsers = [
    {
      name = user;
      ensureDBOwnership = true;
    }
  ];

  services.pr-tracker.api.enable = true;
  services.pr-tracker.api.package = pr-tracker.packages.${system}.api.overrideAttrs {dontStrip = true;};
  systemd.services.pr-tracker-api.environment.RUST_BACKTRACE = "1";
  services.pr-tracker.api.port = port;
  services.pr-tracker.api.user = user;
  services.pr-tracker.db.urlParams.user = user;
  services.pr-tracker.db.urlParams.host = "localhost";
  services.pr-tracker.db.urlParams.port = toString pgPort;
  services.pr-tracker.db.urlParams.dbname = user;
  services.pr-tracker.db.passwordFile = writeText "password-file" dbPass;
  services.pr-tracker.db.isLocal = true;
}
