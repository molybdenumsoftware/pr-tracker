{
  clippy,
  rustPlatform,
  postgresql,
  buildInputs,
  lib,
}: let
  fs = lib.fileset;
in
  rustPlatform.buildRustPackage {
    name = "pr-tracker-api";
    cargoLock.lockFile = ./Cargo.lock;
    src = (
      fs.toSource {
        root = ./.;
        fileset = fs.unions [
          ./Cargo.toml
          ./Cargo.lock
          ./crates
        ];
      }
    );
    buildAndTestSubdir = "crates/pr-tracker-api";
    nativeCheckInputs = [postgresql clippy];
    postCheck = "cargo clippy -- --deny warnings";
    inherit buildInputs;

    meta.mainProgram = "pr-tracker-api";
  }
