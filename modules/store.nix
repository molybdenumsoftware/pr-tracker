{
  perSystem = {
    lib,
    pkgs,
    ...
  }: {
    treefmt.settings.global.excludes = ["crates/store/.sqlx/*"];
    _module.args = {
      POSTGRESQL_INITDB_PATH = lib.getExe' pkgs.postgresql "initdb";
      POSTGRESQL_POSTGRES_PATH = lib.getExe' pkgs.postgresql "postgres";
    };
  };
}
