{
  inputs,
  lib,
  flake-parts-lib,
  ...
}: {
  imports = [inputs.nci.flakeModule];

  options.perSystem = flake-parts-lib.mkPerSystemOption {
    options.nci.projects = lib.mkOption {
      type = lib.types.lazyAttrsOf (lib.types.submoduleWith {
        modules = [
          {
            options.fileset = lib.mkOption {
              type = lib.mkOptionType {
                name = "fileset";
                merge = _loc: defs: lib.fileset.unions (map (def: def.value) defs);
              };
            };
          }
        ];
      });
    };
  };

  config.perSystem = {
    pkgs,
    config,
    ...
  }: {
    nci.projects.default = {
      path = lib.fileset.toSource {
        root = ../.;
        fileset = config.nci.projects.default.fileset;
      };

      fileset = lib.fileset.unions ([
          ../Cargo.toml
          ../Cargo.lock
        ]
        ++ (lib.pipe ../crates [
          builtins.readDir
          (lib.filterAttrs (name: type: type == "directory"))
          (lib.mapAttrsToList (name: type: [
            (../crates + "/${name}/Cargo.toml")
            (lib.fileset.maybeMissing (../crates + "/${name}/build.rs"))
            (../crates + "/${name}/src")
          ]))
          lib.flatten
        ]));

      profiles = {
        dev = {};
        release.runTests = true;
      };
      clippyProfile = "release";
      drvConfig.env.RUSTFLAGS = "--deny warnings";
      export = false;
    };
    devshells.default.devshell.packages = [
      pkgs.rust-analyzer-unwrapped # https://github.com/NixOS/nixpkgs/issues/212439
    ];
    treefmt.programs.rustfmt = {
      enable = true;
      package = config.nci.toolchains.mkBuild pkgs;
    };
  };
}
