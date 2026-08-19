{ self, ... }:
{
  perSystem =
    {
      system,
      nodeToApiTest,
      pkgs,
      ...
    }:
    {
      checks."integration/api/tcp-db" = nodeToApiTest "api with tcp db" (
        let
          dbPass = "api-db-secret";
          pgPort = 5432;
          user = "pr-tracker";
        in
        {
          imports = [ self.nixosModules.api ];

          nixpkgs.hostPlatform = system;

          services = {
            postgresql = {
              enable = true;
              settings.port = pgPort;
              enableTCPIP = true;

              initialScript = pkgs.writeText "postgresql-init-script" ''
                CREATE ROLE "${user}" WITH LOGIN PASSWORD '${dbPass}';
              '';

              authentication = ''
                host   all       all   0.0.0.0/0  md5
              '';

              ensureDatabases = [ user ];

              ensureUsers = [
                {
                  name = user;
                  ensureDBOwnership = true;
                }
              ];
            };

            pr-tracker.api = {
              enable = true;

              package =
                (self.packages.${system}.api.extendModules {
                  modules = [ { mkDerivation.dontStrip = true; } ];
                }).config.public;

              port = 7000;
              user = user;

              db = {
                urlParams = {
                  user = user;
                  host = "localhost";
                  port = toString pgPort;
                  dbname = user;
                };

                passwordFile = pkgs.writeText "password-file" dbPass;
                isLocal = true;
              };
            };
          };
        }
      );
    };
}
