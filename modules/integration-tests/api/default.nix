{
  perSystem = {pkgs, ...}: {
    _module.args.nodeToApiTest = name: node:
      pkgs.nixosTest {
        inherit name;

        nodes.pr_tracker_api = node;

        testScript = ''
          pr_tracker_api.start()
          pr_tracker_api.wait_for_unit("pr-tracker-api.service")
          pr_tracker_api.succeed("curl --fail http://localhost:7000/api/v1/healthcheck")
        '';
      };
  };
  imports = [
    ./tcp-db.nix
    ./default-package.nix
  ];
}
