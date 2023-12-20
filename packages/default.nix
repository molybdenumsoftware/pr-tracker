{pkgs}: let
  inherit
    (pkgs.lib)
    fileset
    ;

  buildInputs =
    if pkgs.stdenv.isDarwin
    then with pkgs; [darwin.apple_sdk.frameworks.SystemConfiguration]
    else if pkgs.stdenv.isLinux
    then with pkgs; [pkg-config openssl]
    else throw "unsupported";

  cargoWorkspaceSrc = fileset.toSource {
    root = ../.;
    fileset = fileset.unions [
      ../Cargo.toml
      ../Cargo.lock
      ../crates
    ];
  };
in {
  api = pkgs.callPackage ./api/package.nix {inherit cargoWorkspaceSrc buildInputs;};
}
