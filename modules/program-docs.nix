{
  perSystem = {config, ...}: {
    packages.program-docs = config.nci.outputs.default.docs;
    checks."packages/program-docs" = config.packages.program-docs;
    nci.projects.default = {
      fileset = ../crates/DATABASE_URL.md;
      includeInProjectDocs = false;
    };
  };
}
