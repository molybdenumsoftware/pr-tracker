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
  user = "pr-tracker";
in {
  imports = [pr-tracker.nixosModules.api];

  nixpkgs.hostPlatform = system;

  services.pr-tracker.db = "createLocally";

  services.pr-tracker.api.enable = true;
  services.pr-tracker.api.port = port;
  services.pr-tracker.api.user = user;
  systemd.services.pr-tracker-api.environment.RUST_BACKTRACE = "1";

  services.pr-tracker.fetcher.enable = true;
  services.pr-tracker.fetcher.user = user;
  services.pr-tracker.fetcher.onCalendar = "*:*:*"; # every single second
  services.pr-tracker.fetcher.githubApiTokenFile = writeText "gh-auth-token" "hunter2";
  services.pr-tracker.fetcher.branchPatterns = ["*"];
  services.pr-tracker.fetcher.repo.owner = "molybdenumsoftware";
  services.pr-tracker.fetcher.repo.name = "pr-tracker";
  systemd.services.pr-tracker-fetcher.environment.RUST_BACKTRACE = "1";
}
