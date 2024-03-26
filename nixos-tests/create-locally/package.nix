{
  pr-tracker,
  lib,
  nixosTest,
}: 
  nixosTest {
    name = "create-locally";

    nodes.pr_tracker = {
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
    };

    testScript = ''
      pr_tracker.start()
      pr_tracker.wait_for_unit("pr-tracker-api.service")
      pr_tracker.succeed("curl --fail http://localhost:7000/api/v1/healthcheck")
      pr_tracker.wait_until_succeeds("journalctl -u pr-tracker-fetcher.service --grep 'error sending request for url'", timeout=60)
    '';
  }
