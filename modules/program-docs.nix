{
  self,
  lib,
  GITHUB_GRAPHQL_SCHEMA,
  ...
}: {
  perSystem = {
    config,
    pkgs,
    ...
  }: {
    packages.program-docs = (config.nci.crates |> lib.attrNames |> lib.trace) config.nci.outputs.default.docs;
    checks.program-docs = config.packages.program-docs;
    # <<< packages.program-docs = config.nci.lib.buildCrate {
    # <<<   src = lib.traceValSeqN 1 (lib.attrNames config.nci.outputs.default) config.nci.projects.default.path;
    # <<<   drvConfig = {
    # <<<     env = {inherit GITHUB_GRAPHQL_SCHEMA;};
    # <<<     rust-crane = {
    # <<<       buildCommand = "doc";
    # <<<       buildFlags = [
    # <<<         "--package"
    # <<<         "pr-tracker-fetcher-config"
    # <<<         "--package"
    # <<<         "pr-tracker-api-config"
    # <<<         "--no-deps"
    # <<<       ];
    # <<<     };
    # <<<   };
    # <<< };
  };
}
