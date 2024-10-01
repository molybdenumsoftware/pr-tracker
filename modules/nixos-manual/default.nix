# https://gitlab.com/rycee/nur-expressions/-/blob/master/doc/default.nix
{
  lib,
  inputs,
  self,
  ...
}: {
  perSystem = {
    self',
    system,
    pkgs,
    ...
  }: let
    inherit
      (lib)
      any
      evalModules
      hasPrefix
      ;

    inherit
      (builtins)
      removeAttrs
      ;

    filterOptions = import ../../filterOptions.nix lib;

    configuration = evalModules {
      modules =
        [
          self.nixosModules.api
          self.nixosModules.fetcher
          {
            nixpkgs.hostPlatform = system;
            system.stateVersion = "24.05";
          }
        ]
        ++ (import "${inputs.nixpkgs}/nixos/modules/module-list.nix");
    };

    options =
      filterOptions
      (path: option: any (hasPrefix "${self}/") option.declarations)
      configuration.options;

    optionsDocs = pkgs.buildPackages.nixosOptionsDoc {
      inherit options;
      variablelistId = "options";
      transformOptions = options: removeAttrs options ["declarations"];
    };
  in {
    packages.nixos-manual = pkgs.stdenv.mkDerivation {
      name = "pr-tracker-nixos-modules-manual";
      src = ./.;
      nativeBuildInputs = [pkgs.nixos-render-docs];

      buildPhase = ''
        mkdir $out

        manpage_urls=$(mktemp)
        echo "{}" > $manpage_urls

        substituteInPlace ./manual.md \
          --subst-var-by \
            OPTIONS_JSON \
            ${optionsDocs.optionsJSON}/share/doc/nixos/options.json

        nixos-render-docs manual html \
          --manpage-urls $manpage_urls \
          --revision provide-because-required-but-seems-to-be-unused \
          manual.md $out/index.html
      '';
    };

    checks."packages/nixos-modules-manual" = self'.packages.nixos-manual;
  };
}
