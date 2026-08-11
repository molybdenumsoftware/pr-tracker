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

    config.fileset = lib.fileset.unions (
      [
        ../Cargo.toml
        ../Cargo.lock
      ]
      ++ (lib.pipe ../crates [
        builtins.readDir
        (lib.filterAttrs (name: type: type == "directory"))
        (lib.mapAttrsToList (
          name: type: [
            (../crates + "/${name}/Cargo.toml")
            (lib.fileset.maybeMissing (../crates + "/${name}/build.rs"))
            (../crates + "/${name}/src")
          ]
        ))
        lib.flatten
      ])
    );
  };

}
