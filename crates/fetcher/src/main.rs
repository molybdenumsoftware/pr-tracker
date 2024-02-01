#![warn(clippy::pedantic)]

use anyhow::{ensure, Context};
use camino::Utf8PathBuf;
use pr_tracker_fetcher::{github::GitHubGraphqlClient, run};
use pr_tracker_store::PgConnection;
use sqlx_core::connection::Connection;
use wildmatch::WildMatch;

fn get_required_environment_variable(name: &str) -> anyhow::Result<String> {
    std::env::var(name).with_context(|| format!("environment variable {name} must be set"))
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    env_logger::init();

    let db_url = get_required_environment_variable("PR_TRACKER_FETCHER_DATABASE_URL")?;
    let mut db_connection = PgConnection::connect(&db_url).await?;

    let github_token = get_required_environment_variable("PR_TRACKER_FETCHER_GITHUB_TOKEN")?;
    let repo_owner = get_required_environment_variable("PR_TRACKER_FETCHER_GITHUB_REPO_OWNER")?;
    let repo_name = get_required_environment_variable("PR_TRACKER_FETCHER_GITHUB_REPO_NAME")?;
    let github_client =
        GitHubGraphqlClient::new(&github_token, repo_owner.clone(), repo_name.clone(), None)
            .unwrap();

    let cache_dir: Utf8PathBuf =
        get_required_environment_variable("PR_TRACKER_FETCHER_CACHE_DIR")?.into();

    ensure!(
        cache_dir.exists(),
        "cache directory must exist: PR_TRACKER_FETCHER_CACHE_DIR={cache_dir}",
    );

    let repo_dir = cache_dir
        .join("repos")
        .join("github.com")
        .join(repo_owner)
        .join(repo_name);

    let branch_patterns = get_required_environment_variable("PR_TRACKER_FETCHER_BRANCH_PATTERNS")?;
    let branch_patterns: Vec<&str> = serde_json::from_str(&branch_patterns)
        .context("PR_TRACKER_FETCHER_BRANCH_PATTERNS must be a JSON array of strings")?;
    let branch_patterns: Vec<WildMatch> = branch_patterns.into_iter().map(WildMatch::new).collect();

    run(
        &mut db_connection,
        github_client,
        &repo_dir,
        &branch_patterns,
    )
    .await?;
    Ok(())
}
