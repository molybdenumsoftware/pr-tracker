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
      drvConfig.env.RUSTFLAGS = "--deny warnings";
      numtideDevshell = "default";
      export = false;
      # from crane usage that is being replaced
      # cargoClippyExtraArgs = "--all-targets --all-features -- --deny warnings";
    };
    # TODO: Check names "packages/fetcher"
    treefmt.programs.rustfmt = {
      enable = true;
      package = config.nci.toolchains.mkBuild pkgs;
    };
  };
}
