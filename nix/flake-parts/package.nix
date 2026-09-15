{
  lib,
  config,
  ...
}:
{
  perSystem =
    psArgs@{ pkgs, ... }:
    {
      options = {
        octokit-graphql-schema = lib.mkOption {
          type = lib.types.package;
          readOnly = true;
          default = pkgs.callPackage (config.projectRoot + "/nix/pkgs/octokit-graphql-schema.nix") { };
        };
        package = lib.mkOption {
          readOnly = true;
          type = lib.types.package;
          default = pkgs.callPackage (config.projectRoot + "/nix/pkgs/pr-tracker.nix") {
            inherit (psArgs.config) octokit-graphql-schema;
          };
        };
      };
      config.checks = { inherit (psArgs.config) package; };
    };
}
