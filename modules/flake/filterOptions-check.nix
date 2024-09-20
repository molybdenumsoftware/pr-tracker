{
  perSystem = {
    pkgs,
    lib,
    ...
  }: let
    filterOptionsCheck = let
      subject = import ../../filterOptions.nix lib;

      tests.testEmpty = {
        expr = subject (p: o: true) {};
        expected = {};
      };

      tests.testNoFilter = {
        expr = subject (p: o: true) {foo-1 = lib.mkOption {};};
        expected = {foo-1 = lib.mkOption {};};
      };

      tests.testFilter = {
        expr = subject (p: o: lib.hasPrefix "foo-" o.description) {
          foo-1 = lib.mkOption {description = "foo-1";};
          bar-1 = lib.mkOption {description = "bar-1";};
        };
        expected = {
          foo-1 = lib.mkOption {description = "foo-1";};
        };
      };

      tests.testFilterDeep = {
        expr = subject (p: o: o.description == "foo") {
          nested.foo = lib.mkOption {description = "foo";};
          nested.bar = lib.mkOption {description = "bar";};
        };
        expected.nested.foo = lib.mkOption {description = "foo";};
      };

      tests.testFilterPath = {
        expr = subject (p: o: lib.elem "foo" p) {
          nested.foo = lib.mkOption {};
          nested.bar = lib.mkOption {};
        };
        expected.nested.foo = lib.mkOption {};
      };

      failures = lib.debug.runTests tests;
    in
      lib.assertMsg (failures == []) (builtins.toJSON failures);
  in {
    checks.filterOptions = assert filterOptionsCheck; pkgs.hello;
  };
}
