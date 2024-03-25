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
  imports = [pr-tracker.nixosModules.unified];

  nixpkgs.hostPlatform = system;

  services.pr-tracker-unified.enable = true;
  systemd.services.pr-tracker-api.environment.RUST_BACKTRACE = "1";
  systemd.services.pr-tracker-fetcher.environment.RUST_BACKTRACE = "1";
  services.pr-tracker-unified.port = port;
  services.pr-tracker-unified.user = user;
  services.pr-tracker-unified.createDatabaseLocally = true;
  services.pr-tracker-unified.branchPatterns = ["*"];
}

