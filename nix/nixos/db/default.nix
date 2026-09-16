{
  config,
  lib,
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

    clientOptions = lib.mkOption {
      internal = true;
      type = lib.types.lazyAttrsOf lib.types.optionDeclaration;
      readOnly = true;
      default = {
        urlParams = lib.mkOption {
          type = lib.types.nullOr (lib.types.attrsOf lib.types.str);
          description = ''
            URL parameters from which to compose the PostgreSQL connection URI.

            Required unless {option}`${options.services.pr-tracker.db.createLocally}` is true.
          '';
          example = {
            user = "pr-tracker";
            host = "localhost";
            port = "5432";
            dbname = "pr-tracker";
          };
          default =
            if config.services.pr-tracker.db.createLocally then
              {
                host = "/run/postgresql";
                port = toString config.services.postgresql.settings.port;
                dbname = config.services.pr-tracker.db.name;
              }
            else
              null;
        };
        passwordFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          description = ''
            Path to a file containing the database password.
            Contents will be appended to the database URL as a parameter.
          '';
          example = "/run/secrets/db-password";
          default = null;
        };
        isLocal = lib.mkOption {
          type = lib.types.bool;
          description = "Whether database is local.";
          default = config.services.pr-tracker.db.createLocally;
        };
      };
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
}
