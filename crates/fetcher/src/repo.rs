use std::ffi::OsStr;

async fn isolated_git(args: impl IntoIterator<Item = impl AsRef<OsStr>>) -> anyhow::Result<()> {
    let status = tokio::process::Command::new("git")
        // Run git, ignoring any existing config files.
        // https://github.com/git/git/blob/v2.43.0/Documentation/git.txt#L708-L716
        .env("GIT_CONFIG_GLOBAL", "/dev/null")
        .env("GIT_CONFIG_SYSTEM", "/dev/null")
        .args(args)
        .status()
        .await?;

    anyhow::ensure!(status.success(), "git exited with {:?}", status.code());
    Ok(())
}

pub async fn fetch_or_clone(
    repo_path: &camino::Utf8Path,
    repo_owner: &str,
    repo_name: &str,
) -> anyhow::Result<()> {
    // TODO: figure out how to do all this with gix. See
    // https://github.com/Byron/gitoxide/issues/1165.

    if repo_path.exists() {
        isolated_git(["-C", repo_path.as_str(), "fetch", "--prune"]).await
    } else {
        isolated_git([
            "clone",
            &format!("https://github.com/{repo_owner}/{repo_name}"),
            "--bare",
            "--filter=tree:0",
            repo_path.as_str(),
        ])
        .await
    }
}

pub async fn write_commit_graph(repo_path: &camino::Utf8Path) -> anyhow::Result<()> {
    isolated_git([
        "-C",
        repo_path.as_str(),
        "commit-graph",
        "write",
        "--reachable",
    ])
    .await
}
