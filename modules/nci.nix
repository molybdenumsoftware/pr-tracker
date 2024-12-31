{inputs, ...}: {
  imports = [inputs.nci.flakeModule];
  perSystem = {
    pkgs,
    config,
    ...
  }: {
    nci.projects.default = {
      path = ../.;
      profiles = {
        dev = {};
        release.runTests = true;
      };
      clippyProfile = "release";
      drvConfig.env.RUSTFLAGS = "--deny warnings";
      export = false;
    };
    devshells.default.devshell.packages = [
      pkgs.rust-analyzer-unwrapped # https://github.com/NixOS/nixpkgs/issues/212439
    ];
    treefmt.programs.rustfmt = {
      enable = true;
      package = config.nci.toolchains.mkBuild pkgs;
    };
  };
}
