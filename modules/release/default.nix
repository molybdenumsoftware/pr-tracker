{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (pkgs) buildNpmPackage cargo-edit writeShellApplication;

      semantic-release = buildNpmPackage {
        pname = "semantic-release-with-plugins";
        version = "1.0.0";
        src = ./semantic-release-with-plugins;
        npmDepsHash = "sha256-QmAtEDIW+tps9lm8kozZzaJlZHfFs4B5oeprbqhUMkg=";
        dontNpmBuild = true;
      };

      bump-version = writeShellApplication {
        name = "bump-version";
        runtimeInputs = [ cargo-edit ];
        text = ''
          cargo set-version "$@"
        '';
      };

      release = writeShellApplication {
        name = "release-pr-tracker";
        runtimeInputs = [ bump-version ];
        text = ''
          ${semantic-release}/bin/semantic-release "$@"
        '';
      };
    in
    {
      apps.bump-version = {
        type = "app";
        program = lib.getExe bump-version;
      };
      apps.release = {
        type = "app";
        program = lib.getExe release;
      };

      treefmt.settings.global.excludes = [
        "CHANGELOG.md"
        "modules/release/semantic-release-with-plugins/package-lock.json"
      ];
    };
}
