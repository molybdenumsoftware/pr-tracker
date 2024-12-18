{lib, ...}: {
  perSystem = {pkgs, ...}: {
    nci.projects.default.drvConfig.env = {
      POSTGRESQL_INITDB = lib.getExe' pkgs.postgresql "initdb";
      POSTGRESQL_POSTGRES = lib.getExe' pkgs.postgresql "postgres";
    };
    devshells.default.env = lib.attrsToList {
      #POSTGRESQL_INITDB = lib.getExe' pkgs.postgresql "initdb";
      #POSTGRESQL_POSTGRES = lib.getExe' pkgs.postgresql "postgres";
    };
  };
}
