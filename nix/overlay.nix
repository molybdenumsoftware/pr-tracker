final: prev: {
  octokit-graphql-schema = final.callPackage ./pkgs/octokit-graphql-schema { };
  pr-tracker = prev.callPackage ./pkgs/pr-tracker { };

  pr-tracker-api = final.lib.recursiveUpdate final.pr-tracker {
    meta.mainProgram = "pr-tracker-api";
  };
  pr-tracker-fetcher = final.lib.recursiveUpdate final.pr-tracker {
    meta.mainProgram = "pr-tracker-fetcher";
  };
}
