{
  perSystem =
    {
      pkgs,
      ...
    }:
    {
      chapters.vision = {
        title = "Vision";
        drv = pkgs.writeTextFile {
          name = "vision.md";
          text =
            # markdown
            ''
              ## Push-driven updates

              The current architecture of obtaining data via polling allows instantaneous
              and hopefully reliable responses.
              However, the data can be stale.

              In the future, we intend to provide fresher data by subscribing to GitHub webhooks.

              Since the public cannot subscribe to GitHub webhooks,
              this will require deployment by the repo owner.

              ## Event record keeping

              Building upon the implementation of push-driven updates,
              we intend to keep track of _when_ PRs land in branches.
              This requires a dataset of landings.

              ## Webhook service

              We intend to allow users to subscribe to webhook notifications of PR landings.
              This provides a couple of benefits over subscribing to GitHub webhooks directly:

              - GitHub webhooks can only notify when a PR lands in its target branch. They
                cannot notify when that PR lands in other branches.
              - Only repo owners can subscribe to GitHub webhooks.

              ## Backport PRs

              A backport PR is a re-application of another PR, targeting a different branch.

              We intend to adopt or invent a workflow whereby in backport PRs the original PR is declared.
              Using that metadata, when providing landings for an original PR,
              we intend to also include branches on which a backport PR had landed.
            '';
        };
      };
    };
}
