{ inputs, lib, ... }:
{
  flake-file.inputs.devshell = {
    url = "github:numtide/devshell";
    flake = false;
  };
  imports = [
    "${inputs.devshell}/flake-module.nix"
  ];
  perSystem =
    psArgs@{ pkgs, ... }:
    {
      checks.devshell = psArgs.config.devShells.default;
      devshells.default = {
        env = lib.attrsToList pkgs.pr-tracker.passthru.env;
        packages = with pkgs; [
          gcc
          cargo
          rustc
          clippy
          rust-analyzer-unwrapped # https://github.com/NixOS/nixpkgs/issues/212439
        ];
      };
    };
}
