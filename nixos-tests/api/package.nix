{
  lib,
  modules,
  nixosTest,
  system,
}: let
  inherit
    (lib)
    mkDefault
    ;

  inherit
    (builtins)
    toString
    ;

  port = 7000;
  pgPort = 5432;
  urlRoot = "http://localhost:${toString port}";
  user = "pr-tracker";
in
  nixosTest {
    name = "api module test";

    nodes.pr_tracker_api = {
      pkgs,
      config,
      ...
    }: {
      imports = [modules.api];

      nixpkgs.hostPlatform = system;

      services.postgresql.enable = true;
      services.postgresql.port = pgPort;
      services.postgresql.ensureDatabases = [user];
      services.postgresql.ensureUsers = [
        {
          name = user;
          ensureDBOwnership = true;
        }
      ];

      services.pr-tracker-api.enable = true;
      services.pr-tracker-api.port = port;
      services.pr-tracker-api.user = user;
      services.pr-tracker-api.databaseUrl = "postgresql:///${user}?host=/run/postgresql&port=${builtins.toString pgPort}";
      services.pr-tracker-api.localDb = true;
    };

    testScript = ''
      pr_tracker_api.start()
      pr_tracker_api.wait_for_unit("pr-tracker-api.service")
      pr_tracker_api.succeed("curl --fail ${urlRoot}/api/v1/healthcheck")
    '';
  }
