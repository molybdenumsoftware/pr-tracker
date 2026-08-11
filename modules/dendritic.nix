{ inputs, ... }: {

  flake-file.inputs = {
    flake-file = {
      url = "github:denful/flake-file";
      flake = false;
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    import-tree.url = "github:denful/import-tree";
  };

  imports = [ (import "${inputs.flake-file}/modules").flakeModules.default ];
}
