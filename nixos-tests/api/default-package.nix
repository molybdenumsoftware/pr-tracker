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
  services.postgresql.settings.port = pgPort;
  services.postgresql.ensureDatabases = [user];
  services.postgresql.ensureUsers = [
    {
      name = user;
      ensureDBOwnership = true;
    }
  ];

  services.pr-tracker.api.enable = true;
  systemd.services.pr-tracker-api.environment.RUST_BACKTRACE = "1";
  services.pr-tracker.api.port = port;
  services.pr-tracker.api.user = user;
  services.pr-tracker.api.db.urlParams.host = "/run/postgresql";
  services.pr-tracker.api.db.urlParams.port = toString pgPort;
  services.pr-tracker.api.db.urlParams.dbname = user;
  services.pr-tracker.api.db.isLocal = true;
}
