# https://gitlab.com/rycee/nur-expressions/-/blob/master/doc/default.nix
{
  src,
  pr-tracker,
  nixos-render-docs,
  stdenv,
  lib,
  buildPackages,
  nixpkgs,
  system,
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
        pr-tracker.nixosModules.api
        pr-tracker.nixosModules.fetcher
        {
          nixpkgs.hostPlatform = system;
          system.stateVersion = "24.05";
        }
      ]
      ++ (import "${nixpkgs}/nixos/modules/module-list.nix");
  };

  options =
    filterOptions
    (path: option: any (hasPrefix "${pr-tracker}/") option.declarations)
    configuration.options;

  optionsDocs = buildPackages.nixosOptionsDoc {
    inherit options;
    variablelistId = "options";
    transformOptions = options: removeAttrs options ["declarations"];
  };
in
  stdenv.mkDerivation {
    name = "pr-tracker-nixos-modules-manual";
    src = ./.;
    nativeBuildInputs = [nixos-render-docs];

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
  }
