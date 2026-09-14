{ self, ... }:
{
  perSystem =
    {
      system,
      nodeToApiTest,
      ...
    }:
    {
      checks."integration/api/default-package" = nodeToApiTest "api with default pacakge" {
        imports = [ self.nixosModules.api ];

        nixpkgs.hostPlatform = { inherit system; };

        services.pr-tracker = {
          api = {
            enable = true;
            port = 7000;
            user = "pr-tracker-api";
          };

          db.createLocally = true;
        };

        systemd.services.pr-tracker-api.environment.RUST_BACKTRACE = "1";
      };
    };
}
