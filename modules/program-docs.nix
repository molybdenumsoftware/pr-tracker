{
  perSystem = {
    config,
    ...
  }: {
    packages.program-docs = config.nci.outputs.default.docs;
    checks.program-docs = config.packages.program-docs;
  };
}
