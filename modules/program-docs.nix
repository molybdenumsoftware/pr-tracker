{
  perSystem = {
    config,
    lib,
    ...
  }: {
    packages.program-docs = config.nci.outputs.default.docs;
    checks."packages/program-docs" = config.packages.program-docs;

    nci.crates =
      lib.pipe config.nci.outputs
      [
        lib.attrNames
        (map (crateName:
          lib.nameValuePair crateName {
            excludeFromProjectDocs = lib.mkDefault true;
          }))
        lib.listToAttrs
      ];
  };
}
