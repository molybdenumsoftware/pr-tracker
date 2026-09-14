{ inputs, ... }: {
  flake-file.inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  perSystem = { system, ... }: {
    imports = [ "${inputs.nixpkgs}/nixos/modules/misc/nixpkgs.nix" ];
    nixpkgs = { inherit system; };
  };
}
