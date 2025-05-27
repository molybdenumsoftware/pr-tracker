{
  perSystem =
    { config, ... }:
    {
      packages.program-docs = config.nci.outputs.default.docs;
      checks."packages/program-docs" = config.packages.program-docs;
      nci.projects.default.includeInProjectDocs = false;
    };
}
