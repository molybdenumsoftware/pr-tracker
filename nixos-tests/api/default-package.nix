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
  port = 7000;
  pgPort = 5432;
  user = "pr-tracker";
in {
  imports = [pr-tracker.nixosModules.api];

  nixpkgs.hostPlatform = system;

  services.postgresql.enable = true;
  services.postgresql.port = pgPort;
  services.postgresql.ensureDatabases = [user];
  services.postgresql.ensureUsers = [
    {
      name = user;
      ensureDBOwnership = true;
    }
  ];

  services.pr-tracker-api.enable = true;
  systemd.services.pr-tracker-api.environment.RUST_BACKTRACE = "1";
  services.pr-tracker-api.port = port;
  services.pr-tracker-api.user = user;
  services.pr-tracker-api.dbUrlParams.host = "/run/postgresql";
  services.pr-tracker-api.dbUrlParams.port = toString pgPort;
  services.pr-tracker-api.dbUrlParams.dbname = user;
  services.pr-tracker-api.localDb = true;
}
