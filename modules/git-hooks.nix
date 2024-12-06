{inputs, ...}: {
  imports = [inputs.git-hooks-nix.flakeModule];
  perSystem.pre-commit.check.enable = false;
}
