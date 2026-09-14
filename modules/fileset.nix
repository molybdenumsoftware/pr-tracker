{
  lib,
  ...
}:
{
  perSystem = {
    options.fileset = lib.mkOption {
      type = lib.mkOptionType {
        name = "fileset";
        merge = _loc: defs: lib.fileset.unions (map (def: def.value) defs);
      };
    };

    config.fileset = lib.fileset.fileFilter (
      file: file.name == "Cargo.toml" || file.name == "Cargo.lock" || file.hasExt "rs"
    ) ../.;
  };

}
