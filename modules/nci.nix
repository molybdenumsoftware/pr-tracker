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
    };
    devshells.default.devshell.packages = [pkgs.rust-analyzer];
    treefmt.programs.rustfmt = {
      enable = true;
      package = config.nci.toolchains.mkBuild pkgs;
    };
  };
}
