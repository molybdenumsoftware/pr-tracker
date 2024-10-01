{self, ...}: {
  perSystem = {pkgs, ...}: {
    _module.args.nodeToFetcherTest = name: node:
      pkgs.nixosTest {
        inherit name;

        nodes.pr_tracker_fetcher = node;

        testScript = ''
          pr_tracker_fetcher.start()
          pr_tracker_fetcher.wait_until_succeeds("journalctl -u pr-tracker-fetcher.service --grep 'error sending request for url'", timeout=60)
        '';
      };
  };

  imports = [
    ./tcp-db.nix
    ./default-package.nix
  ];
}
