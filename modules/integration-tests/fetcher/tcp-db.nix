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
      checks."integration/fetcher/tcp-db" = nodeToFetcherTest "fetcher with tcp db" (
        let

          pgPort = 5432;
          user = "pr-tracker";
          dbPass = "fetcher-db-secret";
        in
        {
          imports = [ self.nixosModules.fetcher ];

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

            pr-tracker = {
              fetcher = {
                enable = true;

                package =
                  (self.packages.${system}.fetcher.extendModules {
                    modules = [ { mkDerivation.dontStrip = true; } ];
                  }).config.public;

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

                onCalendar = "*:*:*";
                githubApiTokenFile = pkgs.writeText "gh-auth-token" "hunter2";
                branchPatterns = [ "*" ];

                repo = {
                  owner = "molybdenumsoftware";
                  name = "pr-tracker";
                };
              };
            };
          };
        }
      );
    };
}
