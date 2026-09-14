{ inputs, lib, ... }: {

  flake-file.inputs = {
    flake-file = {
      url = "github:denful/flake-file";
      flake = false;
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };
    import-tree = {
      url = "github:denful/import-tree";
      flake = false;
    };
    files = {
      url = "github:mightyiam/files";
      flake = false;
    };
  };

  imports = [
    (import "${inputs.flake-file}/modules").flakeModules.default
    "${inputs.files}/flake-module.nix"
  ];

  perSystem = psArgs: {
    files.writer.app = true;

    treefmt.settings.global.excludes = lib.attrNames psArgs.config.files.file;
  };
}
