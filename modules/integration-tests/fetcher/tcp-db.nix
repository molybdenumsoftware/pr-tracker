{self, ...}: {
  perSystem = {
    nodeToFetcherTest,
    pkgs,
    ...
  }: {
    checks."integration/fetcher/tcp-db" = nodeToFetcherTest "fetcher with tcp db" (let
      inherit
        (pkgs)
        system
        writeText
        ;

      pgPort = 5432;
      user = "pr-tracker";
      dbPass = "fetcher-db-secret";
    in {
      imports = [self.nixosModules.fetcher];

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
      services.postgresql.ensureDatabases = [user];
      services.postgresql.ensureUsers = [
        {
          name = user;
          ensureDBOwnership = true;
        }
      ];

      services.pr-tracker.fetcher.enable = true;
      services.pr-tracker.fetcher.package =
        (self.packages.${system}.fetcher.extendModules
          {
            modules = [{mkDerivation.dontStrip = true;}];
          })
        .config
        .public;
      systemd.services.pr-tracker-fetcher.environment.RUST_BACKTRACE = "1";
      services.pr-tracker.fetcher.user = user;
      services.pr-tracker.fetcher.db.urlParams.user = user;
      services.pr-tracker.fetcher.db.urlParams.host = "localhost";
      services.pr-tracker.fetcher.db.urlParams.port = toString pgPort;
      services.pr-tracker.fetcher.db.urlParams.dbname = user;
      services.pr-tracker.fetcher.db.passwordFile = writeText "password-file" dbPass;
      services.pr-tracker.fetcher.db.isLocal = true;
      services.pr-tracker.fetcher.onCalendar = "*:*:*"; # every single second
      services.pr-tracker.fetcher.githubApiTokenFile = writeText "gh-auth-token" "hunter2";
      services.pr-tracker.fetcher.branchPatterns = ["*"];
      services.pr-tracker.fetcher.repo.owner = "molybdenumsoftware";
      services.pr-tracker.fetcher.repo.name = "pr-tracker";
    });
  };
}
