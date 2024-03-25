{
  pr-tracker,
  lib,
  nixosTest,
}: let
  nodeToTest = name: node:
    nixosTest {
      inherit name;

      nodes.pr_tracker_unified = node;

      testScript = ''
        pr_tracker_unified.start()
        pr_tracker_unified.wait_until_succeeds("journalctl -u pr-tracker-fetcher.service --grep 'error sending request for url'", timeout=60)
        pr_tracker_unified.wait_for_unit("pr-tracker-api.service")
        pr_tracker_unified.succeed("curl --fail http://localhost:7000/api/v1/healthcheck")
      '';
    };
in {
  create-db-locally = nodeToTest "unified with auto created db" (import ./create-db-locally.nix pr-tracker);
  with-manual-db = nodeToTest "unified with manually created db" (import ./with-manual-db.nix pr-tracker);
}
