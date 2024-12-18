{inputs, ...}: {
  imports = [inputs.nci.flakeModule];
  perSystem = {
    pkgs,
    config,
    ...
  }: {
    nci.projects.default = {
      path = ../.;
      profiles.release.runTests = true;
      clippyProfile = "release";
      # <<< drvConfig.env.RUSTFLAGS = "--deny warnings";
      numtideDevshell = "default";
      export = false;
      # from crane usage that is being replaced
      # cargoClippyExtraArgs = "--all-targets --all-features -- --deny warnings";
    };
    devshells.default.devshell.packages = [pkgs.rust-analyzer];
    # TODO test `cargo test` in the devshell
    treefmt.programs.rustfmt = {
      enable = true;
      package = config.nci.toolchains.mkBuild pkgs;
    };
  };
}
