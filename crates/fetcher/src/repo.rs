use std::ffi::OsStr;

use anyhow::bail;
use camino::Utf8Path;

/// Run git, ignoring any existing config files.
///
/// <https://github.com/git/git/blob/v2.43.0/Documentation/git.txt#L708-L716>
pub async fn isolated_git(
    args: impl IntoIterator<Item = impl AsRef<OsStr>>,
) -> anyhow::Result<std::process::Output> {
    let mut command = tokio::process::Command::new(env!("GIT"));

    command
        .env("GIT_CONFIG_GLOBAL", "/dev/null")
        .env("GIT_CONFIG_SYSTEM", "/dev/null")
        .env("GIT_AUTHOR_NAME", "PR Tracker")
        .env("GIT_COMMITTER_NAME", "PR Tracker")
        .env("GIT_AUTHOR_EMAIL", "pr-tracker@example.com")
        .env("GIT_COMMITTER_EMAIL", "pr-tracker@example.com")
        .args(args);

    let output = command.output().await?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        let status_code = output.status.code();

        bail!("git {command:?}\n exited with {status_code:?}\n stderr: {stderr}\n");
    }

    Ok(output)
}

pub async fn fetch_or_clone(repo_path: &Utf8Path, remote: &str) -> anyhow::Result<()> {
    if repo_path.exists() {
        isolated_git([
            "-C",
            repo_path.as_str(),
            "fetch",
            "--force",
            "--prune",
            "origin",
            "refs/heads/*:refs/heads/*",
        ])
        .await?;
    } else {
        isolated_git([
            "clone",
            remote,
            "--bare",
            "--filter=tree:0",
            repo_path.as_str(),
        ])
        .await?;
    }

    Ok(())
}

pub async fn write_commit_graph(repo_path: &Utf8Path) -> anyhow::Result<()> {
    isolated_git([
        "-C",
        repo_path.as_str(),
        "commit-graph",
        "write",
        "--reachable",
    ])
    .await?;
    Ok(())
}
