{GITHUB_GRAPHQL_SCHEMA,...}: {
  perSystem = {
    config,
    lib,
    pkgs,
    ...
  }: {

    #<<< TODO: extract >>>
    # nci.crates.db-context.drvConfig.env = {
    #   POSTGRESQL_INITDB = lib.getExe' pkgs.postgresql "initdb";
    #   POSTGRESQL_POSTGRES = lib.getExe' pkgs.postgresql "postgres";
    #   GIT = lib.getExe pkgs.git;
    # };
    nci.projects.default.drvConfig.env = assert lib.assertMsg false "inside program-docs.nix. we hit this assertion because we commented out the corresponding setting in modules/nci.nix"; {
    # <<< nci.crates.util.drvConfig.env = {
      POSTGRESQL_INITDB = lib.getExe' pkgs.postgresql "initdb";
      POSTGRESQL_POSTGRES = lib.getExe' pkgs.postgresql "postgres";
     inherit GITHUB_GRAPHQL_SCHEMA;
      GIT = lib.getExe pkgs.git;
    };
    nci.projects.default.depsDrvConfig.env = {
    # <<< nci.crates.util.drvConfig.env = {
      POSTGRESQL_INITDB = lib.getExe' pkgs.postgresql "initdb";
      POSTGRESQL_POSTGRES = lib.getExe' pkgs.postgresql "postgres";
      GIT = lib.getExe pkgs.git;
    };
    #<<< TODO: extract >>>

    packages.program-docs = config.nci.outputs.default.docs.overrideAttrs {
      env = {
        POSTGRESQL_INITDB = lib.getExe' pkgs.postgresql "initdb";
        POSTGRESQL_POSTGRES = lib.getExe' pkgs.postgresql "postgres";
        GIT = lib.getExe pkgs.git;
      };
    };
    # <<< packages.program-docs = lib.traceSeqN 2 config.nci.crates config.nci.outputs.default.docs;
    checks.program-docs = config.packages.program-docs;
  };
}
