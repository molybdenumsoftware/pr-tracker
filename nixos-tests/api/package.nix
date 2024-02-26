{
  pr-tracker,
  lib,
  nixosTest,
}: let
  nodeToTest = name: node:
    nixosTest {
      inherit name;

      nodes.pr_tracker_api = node;

      testScript = ''
        pr_tracker_api.start()
        pr_tracker_api.wait_for_unit("pr-tracker-api.service")
        pr_tracker_api.succeed("curl --fail http://localhost:7000/api/v1/healthcheck")
      '';
    };
in {
  tcp-db = nodeToTest "api with tcp db" (import ./tcp-db.nix pr-tracker);
  socket-db = nodeToTest "api with socket db" (import ./socket-db.nix pr-tracker);
}
