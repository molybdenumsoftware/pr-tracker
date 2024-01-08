{
  lib,
  buildInputs,
  cargoWorkspaceSrc,
  nativeCheckInputs,
  rustPlatform,
}:
rustPlatform.buildRustPackage {
  name = "pr-tracker-api";
  cargoLock.lockFile = ../../Cargo.lock;
  src = cargoWorkspaceSrc;
  buildAndTestSubdir = "crates/api";
  postCheck = "cargo clippy -- --deny warnings";
  inherit buildInputs nativeCheckInputs;

  meta.mainProgram = "pr-tracker-api";
}
