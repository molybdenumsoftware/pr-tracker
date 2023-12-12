{
  rustPlatform,
  postgresql,
  buildInputs,
}:
rustPlatform.buildRustPackage {
  name = "pr-tracker-api";
  cargoLock.lockFile = ./Cargo.lock;
  src = ./.;
  buildAndTestSubdir = "pr-tracker-api";
  nativeCheckInputs = [postgresql];
  inherit buildInputs;
}
