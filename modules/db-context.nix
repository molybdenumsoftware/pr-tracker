{lib, ...}: {
  perSystem = {pkgs, ...}: {
    devshells.default.env = lib.attrsToList {
      POSTGRESQL_INITDB = lib.getExe' pkgs.postgresql "initdb";
      POSTGRESQL_POSTGRES = lib.getExe' pkgs.postgresql "postgres";
    };
  };
}
