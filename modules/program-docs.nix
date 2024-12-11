{
  perSystem = {
    config,
    lib,
    pkgs,
    ...
  }: {

    #<<< TODO: extract >>>
    nci.crates.db-context.drvConfig.mkDerivation.env = {
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
