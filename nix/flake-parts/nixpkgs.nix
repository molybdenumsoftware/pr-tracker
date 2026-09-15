{ inputs, config, ... }: {
  flake-file.inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  perSystem = { system, pkgs, ... }: {
    imports = [ "${inputs.nixpkgs}/nixos/modules/misc/nixpkgs.nix" ];
    nixpkgs = {
      inherit system;
      overlays = [ (import (config.projectRoot + "/nix/overlay.nix")) ];
    };
    legacyPackages = pkgs;
    checks = { inherit (pkgs) octokit-graphql-schema pr-tracker; };
  };
}
