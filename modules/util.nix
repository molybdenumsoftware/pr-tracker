{
  perSystem = {pkgs, ...}: {
    treefmt.settings.global.excludes = ["crates/util/migrations/*"];
    devshells.default.devshell.packages = [
      (pkgs.writeShellApplication {
        name = "util-sqlx-prepare";
        runtimeInputs = [pkgs.sqlx-cli];
        text = "cargo run --package util --bin sqlx-prepare";
      })

      (pkgs.writeShellApplication {
        name = "util-db-repl";
        text = "cargo run --package util --bin db-repl";
      })
    ];
  };
}
