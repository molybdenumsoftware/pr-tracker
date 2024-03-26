{
  pr-tracker,
  lib,
  nixosTest,
}: let
  nodeToTest = name: node:
    nixosTest {
      inherit name;

      nodes.pr_tracker_api = node;

      testScript = ''
        pr_tracker_api.start()
        pr_tracker_api.wait_for_unit("pr-tracker-api.service")
        pr_tracker_api.succeed("curl --fail http://localhost:7000/api/v1/healthcheck")
      '';
    };
in {
  tcp-db = nodeToTest "api with tcp db" (import ./tcp-db.nix pr-tracker);
  socket-db = nodeToTest "api with socket db" (import ./socket-db.nix pr-tracker);
  default-package = nodeToTest "api with default package" (import ./default-package.nix pr-tracker);
}
{
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
in {
  imports = [pr-tracker.nixosModules.api];

  nixpkgs.hostPlatform = system;

  services.pr-tracker.db = "createLocally";

  services.pr-tracker.api.package = pr-tracker.packages.${system}.api.overrideAttrs {dontStrip = true;};
  services.pr-tracker.api.enable = true;
  services.pr-tracker.api.port = port;
  systemd.services.pr-tracker-api.environment.RUST_BACKTRACE = "1";

  services.pr-tracker.fetcher.package = pr-tracker.packages.${system}.fetcher.overrideAttrs {dontStrip = true;};
  services.pr-tracker.fetcher.enable = true;
  services.pr-tracker.fetcher.onCalendar = "*:*:*"; # every single second
  services.pr-tracker.fetcher.githubApiTokenFile = writeText "gh-auth-token" "hunter2";
  services.pr-tracker.fetcher.branchPatterns = ["*"];
  services.pr-tracker.fetcher.repo.owner = "molybdenumsoftware";
  services.pr-tracker.fetcher.repo.name = "pr-tracker";
  systemd.services.pr-tracker-fetcher.environment.RUST_BACKTRACE = "1";
}
