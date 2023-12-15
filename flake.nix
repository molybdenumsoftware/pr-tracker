{
  inputs = {
    # pinned to avoid a later broken rustfmt https://github.com/NixOS/nixpkgs/issues/273920
    nixpkgs.url = github:NixOS/nixpkgs/fb22f402f47148b2f42d4767615abb367c1b7cfd;
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    treefmt-nix,
    flake-utils,
  }: let
    inherit
      (nixpkgs.lib)
      attrValues
      getExe
      pipe
      hasSuffix
      ;

    forEachDefaultSystem = system: let
      buildInputs =
        if hasSuffix "-darwin" system
        then with pkgs; [darwin.apple_sdk.frameworks.SystemConfiguration]
        else if hasSuffix "-linux" system
        then with pkgs; [pkg-config openssl]
        else throw "unsupported";
      pkgs = nixpkgs.legacyPackages.${system};
      treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
      packages.api = pkgs.callPackage ./api.nix {inherit buildInputs;};

      sqlxPrepare = pkgs.writeShellApplication {
        name = "util-sqlx-prepare";
        runtimeInputs = [pkgs.sqlx-cli];
        text = "cargo run --package util --bin sqlx-prepare";
      };

      dbRepl = pkgs.writeShellApplication {
        name = "util-db-repl";
        text = "cargo run --package util --bin db-repl";
      };
    in {
      inherit packages;

      devShells.default = pkgs.mkShell {
        inputsFrom = attrValues packages;
        packages = with pkgs; [rustfmt rust-analyzer];
        SQLX_OFFLINE = "true";
      };

      apps.sqlx-prepare = {
        type = "app";
        program = getExe sqlxPrepare;
      };

      apps.db-repl = {
        type = "app";
        program = getExe dbRepl;
      };

      checks =
        packages
        // {
          formatting = treefmtEval.config.build.check self;
        };

      formatter = treefmtEval.config.build.wrapper;
    };
  in
    flake-utils.lib.eachDefaultSystem forEachDefaultSystem;
}
