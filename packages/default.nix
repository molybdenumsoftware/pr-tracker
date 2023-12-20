{
  pkgs,
  cargoWorkspaceSrc,
  buildInputs,
}: {
  api = pkgs.callPackage ./api/package.nix {inherit cargoWorkspaceSrc buildInputs;};
}
