{
  perSystem = {
    config,
    lib,
    ...
  }: {
    packages.program-docs = config.nci.outputs.default.docs;
    checks."packages/program-docs" = config.packages.program-docs;

    nci.crates =
      lib.pipe (lib.trace config.nci.outputs.default config.nci.outputs) #<<< TODO: default is also in here? >>>
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
