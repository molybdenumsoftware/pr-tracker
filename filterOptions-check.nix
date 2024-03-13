lib @ {
  assertMsg,
  debug,
  hasPrefix,
  mkOption,
  elem,
  ...
}: let
  subject = import ./filterOptions.nix lib;

  tests.testEmpty = {
    expr = subject (p: o: true) {};
    expected = {};
  };

  tests.testNoFilter = {
    expr = subject (p: o: true) {foo-1 = mkOption {};};
    expected = {foo-1 = mkOption {};};
  };

  tests.testFilter = {
    expr = subject (p: o: hasPrefix "foo-" o.description) {
      foo-1 = mkOption {description = "foo-1";};
      bar-1 = mkOption {description = "bar-1";};
    };
    expected = {
      foo-1 = mkOption {description = "foo-1";};
    };
  };

  tests.testFilterDeep = {
    expr = subject (p: o: o.description == "foo") {
      nested.foo = mkOption {description = "foo";};
      nested.bar = mkOption {description = "bar";};
    };
    expected.nested.foo = mkOption {description = "foo";};
  };

  tests.testFilterPath = {
    expr = subject (p: o: elem "foo" p) {
      nested.foo = mkOption {};
      nested.bar = mkOption {};
    };
    expected.nested.foo = mkOption {};
  };

  failures = debug.runTests tests;
in
  assertMsg (failures == []) (builtins.toJSON failures)
