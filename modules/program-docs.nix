{
  perSystem = {
    config,
    lib,
    pkgs,
    ...
  }: {
    packages.program-docs = config.nci.outputs.default.docs;
    # <<< packages.program-docs = lib.traceSeqN 2 config.nci.crates config.nci.outputs.default.docs;
    # nci.crates.docs.drvConfig.env = {
    #   POSTGRESQL_INITDB = lib.getExe' pkgs.postgresql "initdb";
    #   POSTGRESQL_POSTGRES = lib.getExe' pkgs.postgresql "postgres";
    #   GIT = lib.getExe pkgs.git;
    # };
    checks.program-docs = config.packages.program-docs;
  };
}
