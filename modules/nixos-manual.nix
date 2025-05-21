{
  lib,
  self,
  ...
}:
{
  perSystem =
    {
      self',
      system,
      pkgs,
      ...
    }:
    let
      filterOptions = import ../filterOptions.nix lib;

      configuration = lib.nixosSystem {
        modules = [
          self.nixosModules.api
          self.nixosModules.fetcher
          {
            nixpkgs.hostPlatform = system;
          }
        ];
      };

      options = filterOptions (
        path: option: lib.any (lib.hasPrefix "${self}/") option.declarations
      ) configuration.options;

      optionsDocs = pkgs.buildPackages.nixosOptionsDoc {
        inherit options;
        variablelistId = "options";
        transformOptions = options: builtins.removeAttrs options [ "declarations" ];
      };

      optionsMd =
        pkgs.runCommand "pr-tracker-nixos-options-html" { nativeBuildInputs = [ pkgs.nixos-render-docs ]; }
          ''
            nixos-render-docs options commonmark \
              --manpage-urls <(echo "{}") \
              --revision provide-because-required-but-seems-to-be-unused \
              ${optionsDocs.optionsJSON}/share/doc/nixos/options.json $out
          '';

      summaryMd = pkgs.writeTextFile {
        name = "SUMMARY.md";
        text =
          # markdown
          ''
            [Options](options.md)
          '';
      };
    in
    {
      packages.nixos-manual =
        pkgs.runCommand "pr-tracker-nixos-manual"
          {
            nativeBuildInputs = [ pkgs.mdbook ];
          }
          ''
            mkdir src
            ln -s ${summaryMd} src/SUMMARY.md
            ln -s ${optionsMd} src/options.md
            mdbook build --dest-dir $out
          '';

      checks."packages/nixos-modules-manual" = self'.packages.nixos-manual;
    };
}
