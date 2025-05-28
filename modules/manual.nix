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
            data = [
              {
                title = "NixOS";
                basename = "nixos";
                drv = optionsMd;
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
              lib.concatLines (map (page: "${indent}- [${page.title}](${page.title}.md)") pageTree);
          in
          renderMdList { pageTree = data; }
        # markdown
        # ''
        #   - [NixOS](nixos.md)
        #   - Programs
        #     - [API](api.md)
        #     - [Fetcher](fetcher.md)
        # '';

        ;
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
