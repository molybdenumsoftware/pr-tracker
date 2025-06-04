{
  lib,
  self,
  ...
}:
{
  perSystem =
    psArgs@{
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
            - ${mkChapterLink psArgs.config.chapters.nixos}

            # Programs

            - ${mkChapterLink psArgs.config.chapters.api}
            - ${mkChapterLink psArgs.config.chapters.fetcher}
          '';
      };

      mkChapterLink = { title, basename, ... }: "[${title}](${basename}.md)";
    in
    {
      options = {
        chapters = lib.mkOption {
          type = lib.types.lazyAttrsOf (
            lib.types.submodule (
              { name, ... }:
              {
                options = {
                  title = lib.mkOption {
                    type = lib.types.str;
                  };

                  basename = lib.mkOption {
                    type = lib.types.str;
                    default = name;
                  };

                  drv = lib.mkOption {
                    type = lib.types.package;
                  };
                };
              }
            )
          );
        };
      };
      config = {
        chapters = {
          nixos = {
            title = "NixOS";
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

              ${lib.pipe psArgs.config.chapters [
                (lib.mapAttrsToList (name: chapter: "ln -s ${chapter.drv} src/${chapter.basename}.md"))
                lib.concatLines
              ]}

              mdbook build --dest-dir $out
            '';

        checks."packages/manual" = self'.packages.manual;
      };
    };
}
