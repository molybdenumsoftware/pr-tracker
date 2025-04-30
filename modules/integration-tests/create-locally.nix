{ self, ... }:
let
  apiPort = 7000;
in
{
  perSystem =
    { pkgs, ... }:
    {
      checks."integration/create-locally" = pkgs.nixosTest {
        name = "db.createLocally";

        nodes.pr_tracker =
          { pkgs, ... }:
          let
            inherit (pkgs)
              system
              writeText
              ;
          in
          {
            imports = [
              self.nixosModules.api
              self.nixosModules.fetcher
            ];

            nixpkgs.hostPlatform = system;

            services.pr-tracker.db.createLocally = true;

            services.pr-tracker.api.enable = true;
            services.pr-tracker.api.package =
              (self.packages.${system}.api.extendModules {
                modules = [ { mkDerivation.dontStrip = true; } ];
              }).config.public;
            systemd.services.pr-tracker-api.environment.RUST_BACKTRACE = "1";
            services.pr-tracker.api.port = apiPort;

            services.pr-tracker.fetcher.enable = true;
            services.pr-tracker.fetcher.package =
              (self.packages.${system}.fetcher.extendModules {
                modules = [ { mkDerivation.dontStrip = true; } ];
              }).config.public;
            systemd.services.pr-tracker-fetcher.environment.RUST_BACKTRACE = "1";
            services.pr-tracker.fetcher.onCalendar = "*:*:*"; # every single second
            services.pr-tracker.fetcher.githubApiTokenFile = writeText "gh-auth-token" "hunter2";
            services.pr-tracker.fetcher.branchPatterns = [ "*" ];
            services.pr-tracker.fetcher.repo.owner = "molybdenumsoftware";
            services.pr-tracker.fetcher.repo.name = "pr-tracker";
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
