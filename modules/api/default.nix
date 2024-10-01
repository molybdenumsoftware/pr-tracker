{
  imports = [./nixos-module.nix];

  perSystem = {
    self',
    pkgs,
    buildWorkspacePackage,
    ...
  }: {
    packages.api = buildWorkspacePackage {
      dir = "api";
      nativeCheckInputs = [pkgs.postgresql];
    };

    checks."packages/api" = self'.packages.api;
  };
}
