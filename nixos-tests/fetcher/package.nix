{
  pr-tracker,
  lib,
  pkgs,
  writeText,
}: let
  inherit
    (builtins)
    toString
    ;

  pgPort = 5432;
  user = "pr-tracker";
in
  pkgs.nixosTest {
    name = "fetcher module test";

    nodes.pr_tracker_fetcher = {
      pkgs,
      config,
      ...
    }: {
      imports = [pr-tracker.nixosModules.fetcher];

      nixpkgs.hostPlatform = pkgs.system;

      services.postgresql.enable = true;
      services.postgresql.port = pgPort;
      services.postgresql.ensureDatabases = [user];
      services.postgresql.ensureUsers = [
        {
          name = user;
          ensureDBOwnership = true;
        }
      ];

      services.pr-tracker-fetcher.enable = true;
      services.pr-tracker-fetcher.package = pr-tracker.packages.${pkgs.system}.fetcher.overrideAttrs {dontStrip = true;};
      systemd.services.pr-tracker-fetcher.environment.RUST_BACKTRACE = "1";
      services.pr-tracker-fetcher.user = user;
      services.pr-tracker-fetcher.databaseUrl = "postgresql:///${user}?host=/run/postgresql&port=${builtins.toString pgPort}";
      services.pr-tracker-fetcher.localDb = true;
      services.pr-tracker-fetcher.onCalendar = "*:*:*"; # every single second
      services.pr-tracker-fetcher.githubApiTokenFile = writeText "gh-auth-token" "hunter2";
      services.pr-tracker-fetcher.branchPatterns = ["*"];
      services.pr-tracker-fetcher.repo.owner = "molybdenumsoftware";
      services.pr-tracker-fetcher.repo.name = "pr-tracker";
    };

    testScript = ''
      pr_tracker_fetcher.start()
      pr_tracker_fetcher.wait_until_succeeds("journalctl -u pr-tracker-fetcher.service --grep 'error sending request for url'", timeout=60)
    '';
  }
