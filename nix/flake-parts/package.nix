{
  lib,
  inputs,
  config,
  ...
}:
{
  perSystem =
    psArgs@{ pkgs, ... }:
    {
      options.package = lib.mkOption {
        readOnly = true;
        type = lib.types.package;
        default = pkgs.callPackage (config.projectRoot + "/nix/pkgs/pr-tracker.nix") {
          inherit (inputs) octokit-graphql-schema;
        };
      };
      config.checks = { inherit (psArgs.config) package; };
    };
}
