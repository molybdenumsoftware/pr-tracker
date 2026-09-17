{ config, ... }:
{
  perSystem =
    {
      system,
      pkgs,
      ...
    }:
    {
      checks."integration/fetcher/missing-github-token" = pkgs.testers.nixosTest {
        name = "fetcher with missing GitHub token";

        containers.pr-tracker-fetcher = {
          system.stateVersion = "26.11";
          imports = [
            {
              imports = [ (config.projectRoot + "/nix/nixos/fetcher") ];

              nixpkgs.hostPlatform = system;

              services.pr-tracker = {
                fetcher = {
                  enable = true;
                  user = "pr-tracker-fetcher";
                  onCalendar = "*:*:*";
                  githubApiTokenFile = "/run/secret/hunter2";
                  branchPatterns = [ "*" ];

                  repo = {
                    owner = "molybdenumsoftware";
                    name = "pr-tracker";
                  };
                };

                db.createLocally = true;
              };
            }
          ];
        };

        testScript = ''
          pr_tracker_fetcher.start()
          pr_tracker_fetcher.wait_until_succeeds("journalctl -u pr-tracker-fetcher.service --grep 'No such file or directory'")
          pr_tracker_fetcher.wait_until_succeeds("journalctl -u pr-tracker-fetcher.service --grep 'Failed to start pr-tracker-fetcher.'")
        '';
      };

    };
}
