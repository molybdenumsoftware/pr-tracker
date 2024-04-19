{
  pr-tracker,
  lib,
  nixosTest,
}: let
  nodeToTest = name: node:
    nixosTest {
      inherit name;

      nodes.pr_tracker_fetcher = node;

      testScript = ''
        pr_tracker_fetcher.start()
        pr_tracker_fetcher.wait_until_succeeds("journalctl -u pr-tracker-fetcher.service --grep 'error sending request for url'", timeout=60)
      '';
    };
in {
  tcp-db = nodeToTest "fetcher with tcp db" (import ./tcp-db.nix pr-tracker);
  default-package = nodeToTest "fetcher with default package" (import ./default-package.nix pr-tracker);
}
