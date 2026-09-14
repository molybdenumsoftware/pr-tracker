{ inputs, lib, ... }: {
  imports = [
    (import "${inputs.flake-file}/modules").flakeModules.default
    "${inputs.files}/flake-module.nix"
  ];

  options.projectRoot = lib.mkOption {
    readOnly = true;
    type = lib.types.path;
    default = ../..;
  };

  config = {
    flake-file = {
      outputs =
        # nix
        "inputs: import ./nix/outputs.nix inputs";

      inputs = {
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
    };

    perSystem = psArgs: {
      files.writer.app = true;

      treefmt.settings.global.excludes = lib.attrNames psArgs.config.files.file;
    };
  };
}
