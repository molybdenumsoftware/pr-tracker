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

  # shared
  services.pr-tracker-unified.enable = true;
  services.pr-tracker-unified.createDatabaseLocally = true;
  services.pr-tracker-unified.user = user;
  services.pr-tracker-unified.group = user;

  # api
  services.pr-tracker-unified.port = port;
  systemd.services.pr-tracker-api.environment.RUST_BACKTRACE = "1";

  # fetcher
  services.pr-tracker-unified.branchPatterns = ["*"];
  services.pr-tracker-unified.githubApiTokenFile = writeText "gh-auth-token" "hunter2";
  services.pr-tracker-unified.fetchOnCalendar = "*:*:*"; # every single second
  services.pr-tracker-unified.repo.owner = "molybdenumsoftware";
  services.pr-tracker-unified.repo.name = "pr-tracker";
  systemd.services.pr-tracker-fetcher.environment.RUST_BACKTRACE = "1";
}

