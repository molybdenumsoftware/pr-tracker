{ moduleLocation, lib, ... }:
{
  _module.args.privateNixosModules.db =
    {
      config,
      options,
      ...
    }:
    let

      cfg = config.services.pr-tracker;

      programs = [
        "api"
        "fetcher"
      ];
    in
    {
      # https://github.com/NixOS/nixpkgs/issues/215496
      key = "${moduleLocation}#db";
      _file = "${moduleLocation}#db";

      options.services.pr-tracker.db = {
        createLocally = lib.mkOption {
          type = lib.types.bool;
          description = "Whether to create a local database automatically.";
          default = false;
        };
        name = lib.mkOption {
          type = lib.types.str;
          description = "Automatically created local database name.";
          default = "pr-tracker";
        };
      };

      config = lib.mkIf cfg.db.createLocally {
        assertions = lib.flatten (
          map (
            program:
            let
              programEnabled = lib.hasAttr program cfg && programCfg.enable;
              programCfg = cfg.${program};
              urlParams = programCfg.db.urlParams;
              socketHost = "/run/postgresql";
              msgPrefix = "when `${options.services.pr-tracker.db.createLocally}` then ";
            in
            [
              {
                assertion =
                  (programEnabled && cfg.db.createLocally) -> urlParams ? host && urlParams.host == socketHost;
                message = "${msgPrefix}`services.pr-tracker.${program}.db.urlParams.host` must be `\"${socketHost}\"`";
              }
              {
                assertion =
                  (programEnabled && cfg.db.createLocally) -> urlParams ? dbname && urlParams.dbname == cfg.db.name;
                message = "${msgPrefix}`services.pr-tracker.${program}.db.urlParams.dbname` must equal `${options.services.pr-tracker.db.name}`";
              }
              {
                assertion =
                  (programEnabled && cfg.db.createLocally)
                  -> urlParams ? port && urlParams.port == toString config.services.postgresql.settings.port;
                message = "${msgPrefix}`services.pr-tracker.${program}.db.urlParams.port` must be the stringified value of `services.postgresql.settings.port`";
              }
              {
                assertion = (programEnabled && cfg.db.createLocally) -> programCfg.user != cfg.db.name;
                message = "${msgPrefix}`services.pr-tracker.${program}.user` must be different from `${options.services.pr-tracker.db.name}`";
              }
            ]
          ) programs
        );

        services = {
          postgresql = {
            enable = true;
            ensureDatabases = [ cfg.db.name ];
            ensureUsers = [
              {
                name = cfg.db.name;
                ensureClauses.login = false;
                ensureDBOwnership = true;
              }
            ];
          };
        };
      };

      imports = map (
        program:
        let
          programCfg = cfg.${program};
        in
        {
          config = lib.mkIf (cfg.db.createLocally && lib.hasAttr program cfg && programCfg.enable) {
            services.postgresql.ensureUsers = [ { name = programCfg.user; } ];
            systemd.services.postgresql-setup.postStart = ''
              psql '${cfg.db.name}' -c 'GRANT "${cfg.db.name}" TO "${programCfg.user}"'
              psql '${cfg.db.name}' -c 'ALTER DEFAULT PRIVILEGES FOR ROLE "${programCfg.user}" IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO "${cfg.db.name}"'
              psql '${cfg.db.name}' -c 'ALTER DEFAULT PRIVILEGES FOR ROLE "${programCfg.user}" IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO "${cfg.db.name}"'
            '';
          };
        }
      ) programs;
    };
}
