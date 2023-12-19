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
      optionalAttrs
      pipe
      hasSuffix
      ;

    forEachDefaultSystem = system: let
      pkgs = nixpkgs.legacyPackages.${system};
      buildInputs =
        if pkgs.stdenv.isDarwin
        then with pkgs; [darwin.apple_sdk.frameworks.SystemConfiguration]
        else if pkgs.stdenv.isLinux
        then with pkgs; [pkg-config openssl]
        else throw "unsupported";
      treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
      packages.api = pkgs.callPackage ./api.nix {inherit buildInputs;};

      devUtils = [
        (pkgs.writeShellApplication {
          name = "util-sqlx-prepare";
          runtimeInputs = [pkgs.sqlx-cli];
          text = "cargo run --package util --bin sqlx-prepare";
        })

        (pkgs.writeShellApplication {
          name = "util-db-repl";
          text = "cargo run --package util --bin db-repl";
        })
      ];

      # NixOS tests don't "just work" on Darwin. See
      # https://github.com/NixOS/nixpkgs/issues/254552 for details.
      nixosTests = optionalAttrs (!pkgs.stdenv.isDarwin) {
        api-module = import ./nixos-tests/api.nix {
          modules = systemAgnosticOutputs.nixosModules;
          inherit pkgs;
        };
      };
    in {
      inherit packages;

      devShells.default = pkgs.mkShell {
        inputsFrom = attrValues packages;
        packages = with pkgs;
          [
            rustfmt
            rust-analyzer
          ]
          ++ devUtils;
        SQLX_OFFLINE = "true";
      };

      checks =
        packages
        // nixosTests
        // {
          formatting = treefmtEval.config.build.check self;
        };

      formatter = treefmtEval.config.build.wrapper;
    };
    systemSpecificOutputs = flake-utils.lib.eachDefaultSystem forEachDefaultSystem;
    systemAgnosticOutputs = {
      nixosModules.api = import ./modules/api.nix {pr-tracker = self;};
    };
  in
    systemSpecificOutputs
    // systemAgnosticOutputs;
}
