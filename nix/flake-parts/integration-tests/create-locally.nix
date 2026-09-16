{ config, ... }:
let
  apiPort = 7000;
in
{
  perSystem =
    { system, pkgs, ... }:
    {
      checks."integration/create-locally" = pkgs.testers.nixosTest {
        name = "db.createLocally";

        containers.pr-tracker =
          { pkgs, ... }:
          {
            system.stateVersion = "26.11";

            imports = [
              (config.projectRoot + "/nix/nixos/api")
              (config.projectRoot + "/nix/nixos/fetcher")
            ];

            nixpkgs.hostPlatform = system;

            services = {
              pr-tracker = {
                db.createLocally = true;
                api = {
                  enable = true;
                  port = apiPort;

                };

                fetcher = {
                  enable = true;
                  onCalendar = "*:*:*"; # every single second
                  githubApiTokenFile = pkgs.writeText "gh-auth-token" "hunter2";
                  branchPatterns = [ "*" ];
                  repo = {
                    owner = "molybdenumsoftware";
                    name = "pr-tracker";
                  };
                };

              };

            };

            systemd.services = {
              pr-tracker-api.environment.RUST_BACKTRACE = "1";
              pr-tracker-fetcher.environment.RUST_BACKTRACE = "1";
            };
          };

        testScript = ''
          pr_tracker.start()
          pr_tracker.wait_for_unit("pr-tracker-api.service")
          pr_tracker.succeed("curl --fail http://localhost:${toString apiPort}/api/v2/healthcheck")
          pr_tracker.wait_until_succeeds("journalctl -u pr-tracker-fetcher.service --grep 'error sending request for url'", timeout=60)
        '';
      };
    };
}
