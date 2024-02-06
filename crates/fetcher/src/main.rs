#![warn(clippy::pedantic)]
#![allow(non_snake_case, clippy::struct_field_names)]

use anyhow::{ensure, Context};
use camino::Utf8PathBuf;
use confique::Config;
use pr_tracker_fetcher::{github::GitHubGraphqlClient, run};
use pr_tracker_store::PgConnection;
use sqlx_core::connection::Connection;
use wildmatch::WildMatch;

#[derive(Debug, Config)]
struct Environment {
    #[config(env = "PR_TRACKER_FETCHER_DATABASE_URL")]
    PR_TRACKER_FETCHER_DATABASE_URL: String,
    #[config(env = "PR_TRACKER_FETCHER_GITHUB_TOKEN")]
    PR_TRACKER_FETCHER_GITHUB_TOKEN: String,
    #[config(env = "PR_TRACKER_FETCHER_GITHUB_REPO_OWNER")]
    PR_TRACKER_FETCHER_GITHUB_REPO_OWNER: String,
    #[config(env = "PR_TRACKER_FETCHER_GITHUB_REPO_NAME")]
    PR_TRACKER_FETCHER_GITHUB_REPO_NAME: String,
    #[config(env = "PR_TRACKER_FETCHER_CACHE_DIR")]
    PR_TRACKER_FETCHER_CACHE_DIR: Utf8PathBuf,
    #[config(env = "PR_TRACKER_FETCHER_BRANCH_PATTERNS")]
    PR_TRACKER_FETCHER_BRANCH_PATTERNS: String,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    env_logger::init();

    let config = Environment::builder()
        .env()
        .load()
        .context("loading configuration from environment")?;

    let Environment {
        PR_TRACKER_FETCHER_DATABASE_URL: db_url,
        PR_TRACKER_FETCHER_GITHUB_TOKEN: github_token,
        PR_TRACKER_FETCHER_GITHUB_REPO_OWNER: repo_owner,
        PR_TRACKER_FETCHER_GITHUB_REPO_NAME: repo_name,
        PR_TRACKER_FETCHER_CACHE_DIR: cache_dir,
        PR_TRACKER_FETCHER_BRANCH_PATTERNS: branch_patterns,
    } = config;

    let mut db_connection = PgConnection::connect(&db_url).await?;
    let github_client =
        GitHubGraphqlClient::new(&github_token, repo_owner.clone(), repo_name.clone(), None)
            .unwrap();
    ensure!(
        cache_dir.exists(),
        "cache directory must exist: PR_TRACKER_FETCHER_CACHE_DIR={cache_dir}",
    );
    let repo_dir = cache_dir
        .join("repos")
        .join("github.com")
        .join(repo_owner)
        .join(repo_name);
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
