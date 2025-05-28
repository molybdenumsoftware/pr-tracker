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

      apiMd = abort "TODO-api";
      fetcherMd = abort "TODO-fetcher";

      summaryMd = pkgs.writeTextFile {
        name = "SUMMARY.md";
        text =
          let
<<<<<<< Updated upstream
            data = [
              {
                type = "chapter";
||||||| Stash base
            data = [
              {
=======
            chapters = {
              nixos = {
>>>>>>> Stashed changes
                title = "NixOS";
                basename = "nixos";
                drv = optionsMd;
<<<<<<< Updated upstream
              }
              {
                type = "part";
                title = "Programs";
                chapters = [
                  {
                    type = "chapter";
                    title = "API";
                    basename = "api";
                    drv = pkgs.writeTextFile {
                      name = "api.md";
                      text = "fake api";
                    };
                  }
                  {
                    type = "chapter";
                    title = "Fetcher";
                    basename = "fetcher";
                    drv = pkgs.writeTextFile {
                      name = "fetcher.md";
                      text = "fake fetcher";
                    };
                  }
                ];
              }
            ];
            renderMdList =
              {
                pageTree,
                indent ? "",
              }:
              lib.concatLines (
                lib.flatten (
                  map (
                    {
                      title,
                      basename ? null,
                      children ? null,
                      ... # <<< yuck?
                    }:
                    if (children == null) then
                      "${indent}- [${title}](${basename}.md)" # <<< TODO: need path as well as basename
                    else
                      [
                        "${indent}- [${title}](${title}.md)" # <<< wrong
                        (renderMdList {
                          pageTree = children;
                          indent = "  " + indent;
                        })
                      ]
                  ) pageTree
                )
              );
||||||| Stash base
              }
              {
                title = "Programs";
                children = [
                  {
                    title = "API";
                    basename = "api";
                    drv = pkgs.writeTextFile {
                      name = "api.md";
                      text = "fake api";
                    };
                  }
                  {
                    title = "Fetcher";
                    basename = "fetcher";
                    drv = pkgs.writeTextFile {
                      name = "fetcher.md";
                      text = "fake fetcher";
                    };
                  }
                ];
              }
            ];
            renderMdList =
              {
                pageTree,
                indent ? "",
              }:
              lib.concatLines (
                lib.flatten (
                  map (
                    {
                      title,
                      basename ? null,
                      children ? null,
                      ... # <<< yuck?
                    }:
                    if (children == null) then
                      "${indent}- [${title}](${basename}.md)" # <<< TODO: need path as well as basename
                    else
                      [
                        "${indent}- [${title}](${title}.md)" # <<< wrong
                        (renderMdList {
                          pageTree = children;
                          indent = "  " + indent;
                        })
                      ]
                  ) pageTree
                )
              );
=======
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
>>>>>>> Stashed changes
          in
          # markdown
          ''
            - ${mkChapterLink chapters.nixos}

            # Programs

            - ${mkChapterLink chapters.api}
            - ${mkChapterLink chapters.fetcher}
          '';
      };
    in
    {
      packages.manual =
        pkgs.runCommand "pr-tracker-nixos-manual"
          {
            nativeBuildInputs = [ pkgs.mdbook ];
          }
          ''
            mkdir src
            ln -s ${summaryMd} src/SUMMARY.md
            mdbook build --dest-dir $out
          '';

      checks."packages/manual" = self'.packages.nixos-manual;
    };
}
