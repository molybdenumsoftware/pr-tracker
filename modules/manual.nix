{
  lib,
  self,
  api,
  fetcher,
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
            - ${mkChapterLink chapters.nixos}

            # Programs

            - ${mkChapterLink chapters.api}
            - ${mkChapterLink chapters.fetcher}
          '';
      };

      chapters = {
        nixos = {
          title = "NixOS";
          basename = "nixos";
          drv = optionsMd;
        };
        api = {
          title = "API";
          basename = "api";
          drv = pkgs.writeTextFile {
            name = "api.md";
            text = "fake api";
          };
        };
        fetcher = {
          title = "Fetcher";
          basename = "fetcher";
          drv = pkgs.writeTextFile {
            name = "fetcher.md";
            text = "fake fetcher";
          };
        };
      };
      mkChapterLink = { title, basename, ... }: "[${title}](${basename}.md)";
    in
    {
      packages.manual =
        pkgs.runCommand "pr-tracker-nixos-manual"
          {
            nativeBuildInputs = [
              pkgs.mdbook
              pkgs.coreutils
            ];
          }
          ''
            mkdir src

            ln -s ${summaryMd} src/SUMMARY.md

            ${lib.pipe chapters [
              (lib.mapAttrsToList (name: chapter: "ln -s ${chapter.drv} src/${chapter.basename}.md"))
              lib.concatLines
            ]}

            mdbook build --dest-dir $out
          '';

      checks."packages/manual" = self'.packages.nixos-manual;
    };
}
