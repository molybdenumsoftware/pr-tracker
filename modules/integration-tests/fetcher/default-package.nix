{ self, ... }:
{
  perSystem =
    {
      nodeToFetcherTest,
      system,
      pkgs,
      ...
    }:
    {
      checks."integration/fetcher/default-package" = nodeToFetcherTest "fetcher with default package" {
        imports = [ self.nixosModules.fetcher ];

        nixpkgs.hostPlatform = system;

        services.pr-tracker = {
          fetcher = {
            enable = true;
            user = "pr-tracker-fetcher";
            onCalendar = "*:*:*";
            githubApiTokenFile = pkgs.writeText "gh-auth-token" "hunter2";
            branchPatterns = [ "*" ];

            repo = {
              owner = "molybdenumsoftware";
              name = "pr-tracker";
            };
          };

          db.createLocally = true;
        };

        systemd.services.pr-tracker-fetcher.environment.RUST_BACKTRACE = "1";
      };
    };
}
