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
  services.pr-tracker.api.dbUrlParams.user = user;
  services.pr-tracker.api.dbUrlParams.host = "localhost";
  services.pr-tracker.api.dbUrlParams.port = toString pgPort;
  services.pr-tracker.api.dbUrlParams.dbname = user;
  services.pr-tracker.api.dbPasswordFile = writeText "password-file" dbPass;
  services.pr-tracker.api.localDb = true;
}
