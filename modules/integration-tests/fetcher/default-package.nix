{ self, ... }:
{
  perSystem =
    {
      nodeToFetcherTest,
      pkgs,
      ...
    }:
    {
      checks."integration/fetcher/default-package" = nodeToFetcherTest "fetcher with default package" (
        let
          inherit (pkgs)
            system
            writeText
            ;
          pgPort = 5432;
        in
        {
          imports = [ self.nixosModules.fetcher ];

          nixpkgs.hostPlatform = system;

          services.pr-tracker.fetcher.enable = true;
          systemd.services.pr-tracker-fetcher.environment.RUST_BACKTRACE = "1";
          services.pr-tracker.fetcher.user = "pr-tracker-fetcher";
          services.pr-tracker.db.createLocally = true;
          services.pr-tracker.fetcher.onCalendar = "*:*:*"; # every single second
          services.pr-tracker.fetcher.githubApiTokenFile = writeText "gh-auth-token" "hunter2";
          services.pr-tracker.fetcher.branchPatterns = [ "*" ];
          services.pr-tracker.fetcher.repo.owner = "molybdenumsoftware";
          services.pr-tracker.fetcher.repo.name = "pr-tracker";
        }
      );
    };
}
