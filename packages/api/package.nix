{
  clippy,
  rustPlatform,
  postgresql,
  buildInputs,
  lib,
  cargoWorkspaceSrc,
}:
rustPlatform.buildRustPackage {
  name = "pr-tracker-api";
  cargoLock.lockFile = ../../Cargo.lock;
  src = cargoWorkspaceSrc;
  buildAndTestSubdir = "crates/api";
  nativeCheckInputs = [postgresql clippy];
  postCheck = "cargo clippy -- --deny warnings";
  inherit buildInputs;

  meta.mainProgram = "pr-tracker-api";
}
