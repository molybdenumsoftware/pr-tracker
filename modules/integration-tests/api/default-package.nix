{self, ...}: {
  perSystem = {
    pkgs,
    nodeToApiTest,
    ...
  }: {
    checks."integration/api/default-package" = nodeToApiTest "api with default pacakge" (let
      inherit
        (pkgs)
        system
        ;
      port = 7000;
      pgPort = 5432;
    in {
      imports = [self.nixosModules.api];

      nixpkgs.hostPlatform = system;

      services.pr-tracker.api.enable = true;
      systemd.services.pr-tracker-api.environment.RUST_BACKTRACE = "1";
      services.pr-tracker.api.port = port;
      services.pr-tracker.api.user = "pr-tracker-api";
      services.pr-tracker.db.createLocally = true;
    });
  };
}
