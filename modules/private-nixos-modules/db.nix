{ moduleLocation, ... }:
{
  _module.args.privateNixosModules.db =
    {
      lib,
      config,
      options,
      ...
    }:
    let
      inherit (lib)
        flatten
        hasAttr
        mkIf
        mkOption
        types
        ;

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

      options.services.pr-tracker.db.createLocally = mkOption {
        type = types.bool;
        description = "Whether to create a local database automatically.";
        default = false;
      };

      options.services.pr-tracker.db.name = mkOption {
        type = types.str;
        description = "Automatically created local database name.";
        default = "pr-tracker";
      };

      config = mkIf cfg.db.createLocally {
        assertions = flatten (
          map (
            program:
            let
              programEnabled = hasAttr program cfg && programCfg.enable;
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

        services.postgresql.enable = true;
        services.postgresql.ensureDatabases = [ cfg.db.name ];
        services.postgresql.ensureUsers = [
          {
            name = cfg.db.name;
            ensureClauses.login = false;
            ensureDBOwnership = true;
          }
        ];
      };

      imports = map (
        program:
        let
          programCfg = cfg.${program};
        in
        {
          config = mkIf (cfg.db.createLocally && hasAttr program cfg && programCfg.enable) {
            services.postgresql.ensureUsers = [ { name = programCfg.user; } ];
            systemd.services.postgresql-setup.postStart = ''
              psql '${cfg.db.name}' -c 'GRANT "${cfg.db.name}" TO "${programCfg.user}"'
              psql '${cfg.db.name}' -c 'ALTER DEFAULT PRIVILEGES FOR ROLE "${programCfg.user}" IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO "${cfg.db.name}"'
            '';
          };
        }
      ) programs;
    };
}
