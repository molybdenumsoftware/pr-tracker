{ lib, prefixLines, ... }:
{
  _module.args = {
    psqlConnectionUriMdLink =
      # markdown
      "[PostgreSQL connection URI](https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING-URIS)";

    prefixLines =
      prefix: lines:
      lib.pipe lines [
        (lib.splitString "\n")
        (map (line: prefix + line))
        (lib.concatStringsSep "\n")
      ];

    environmentVariablesToMarkdown = variables: ''
      | Name | Description |
      |------|-------------|
      ${lib.pipe variables [
        (lib.mapAttrsToList (
          name: envVar: "| `${name}` | ${lib.strings.replaceStrings [ "\n" ] [ "<br>" ] envVar.description} |"
        ))
        lib.concatLines
      ]}
    '';
  };

  perSystem =
    { pkgs, ... }:
    {
      _module.args.writeEnvironmentStructFile =
        crateName: environmentVariables:
        let
          fields = lib.pipe environmentVariables [
            (lib.mapAttrsToList (
              envName: envSpec: ''
                ${prefixLines "/// " envSpec.description}
                #[config(env = "${envName}")]
                pub ${envName}: ${envSpec.rustType},''
            ))
            (lib.concatStringsSep "\n")
          ];
        in

        pkgs.writeTextFile {
          name = "${crateName}-env-struct.rs";
          text =
            # rust
            ''
              /// See documentation for each field.
              #[derive(::std::fmt::Debug, ::confique::Config)]
              pub struct Environment {
              ${prefixLines "  " fields}
              }
            '';
        };

      nci.projects.default.fileset = ../crates/util/migrations;
      treefmt.settings.global.excludes = [ "crates/util/migrations/*" ];
      devshells.default.commands = [
        {
          package = pkgs.writeShellApplication {
            name = "util-sqlx-prepare";
            runtimeInputs = [ pkgs.sqlx-cli ];
            text = "exec cargo run --package util --bin sqlx-prepare";
          };
          help = "Update query metadata. See https://github.com/launchbadge/sqlx/blob/v0.8.2/sqlx-cli/README.md#enable-building-in-offline-mode-with-query";
        }
        {
          package = pkgs.writeShellApplication {
            name = "util-db-repl";
            text = "exec cargo run --package util --bin db-repl";
          };
          help = "Start a psql repl connected to a database with migrations applied.";
        }
        {
          package = pkgs.writeShellApplication {
            name = "util-run-api";
            text = ''exec cargo run --package util --bin run-api -- "$@"'';
          };
          help = "Start an API server instance for development.";
        }
      ];
    };
}
