{ self, ... }:
{
  perSystem =
    {
      nodeToApiTest,
      pkgs,
      ...
    }:
    {
      checks."integration/api/tcp-db" = nodeToApiTest "api with tcp db" (
        let
          inherit (pkgs)
            system
            writeText
            ;
          dbPass = "api-db-secret";
          port = 7000;
          pgPort = 5432;
          user = "pr-tracker";
        in
        {
          imports = [ self.nixosModules.api ];

          nixpkgs.hostPlatform = system;

          services.postgresql.enable = true;
          services.postgresql.settings.port = pgPort;
          services.postgresql.enableTCPIP = true;
          services.postgresql.initialScript = writeText "postgresql-init-script" ''
            CREATE ROLE "${user}" WITH LOGIN PASSWORD '${dbPass}';
          '';
          services.postgresql.authentication =
            # type   database  user  address    auth-method
            ''
              host   all       all   0.0.0.0/0  md5
            '';
          services.postgresql.ensureDatabases = [ user ];
          services.postgresql.ensureUsers = [
            {
              name = user;
              ensureDBOwnership = true;
            }
          ];

          services.pr-tracker.api.enable = true;
          services.pr-tracker.api.package =
            (self.packages.${system}.api.extendModules {
              modules = [ { mkDerivation.dontStrip = true; } ];
            }).config.public;
          systemd.services.pr-tracker-api.environment.RUST_BACKTRACE = "1";
          services.pr-tracker.api.port = port;
          services.pr-tracker.api.user = user;
          services.pr-tracker.api.db.urlParams.user = user;
          services.pr-tracker.api.db.urlParams.host = "localhost";
          services.pr-tracker.api.db.urlParams.port = toString pgPort;
          services.pr-tracker.api.db.urlParams.dbname = user;
          services.pr-tracker.api.db.passwordFile = writeText "password-file" dbPass;
          services.pr-tracker.api.db.isLocal = true;
        }
      );
    };
}
