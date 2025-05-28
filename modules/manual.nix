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
            - ${mkChapterLink config.chapters.nixos}

            # Programs

            - ${mkChapterLink config.chapters.api}
            - ${mkChapterLink config.chapters.fetcher}
          '';
      };

      mkChapterLink = { title, basename, ... }: "[${title}](${basename}.md)";
    in
    {
      options = {
        chapters = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                title = lib.mkOption {
                  type = lib.types.string;
                };

                basename = lib.mkOption {
                };
              };
            }
          );
        };
      };
      config = {
        # <<< TODO: debate where to put this. should it really be one chapter or two? >>>
        chapters = {
          nixos = {
            title = "NixOS";
            basename = "nixos";
            drv = optionsMd;
          };
        };

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
    };
}
