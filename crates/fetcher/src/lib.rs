#![warn(clippy::pedantic)]

use crate::github::GitHub;
use itertools::Itertools;

mod github;
mod repo;

#[derive(Debug, Clone, PartialEq)]
pub struct Options {
    pub page_size: u32,
}

impl Default for Options {
    fn default() -> Self {
        Self { page_size: 50 }
    }
}

// master, nixpkgs-unstable, nixpkgs-stable, release-23.11, nixos-23.11

/// Run the darn thing.
///
/// # Errors
///
/// IO that can fail includes database communication, GraphQL requests and git operations.
pub async fn run(
    db_connection: &mut pr_tracker_store::PgConnection,
    repo_owner: &str,
    repo_name: &str,
    github_api_token: &str,
    temp_dir: &camino::Utf8PathBuf,
    branch_patterns: &[wildmatch::WildMatch],
    options: &Options,
) -> anyhow::Result<()> {
    util::migrate(&mut *db_connection).await?;

    update_prs(
        github_api_token,
        repo_owner,
        repo_name,
        db_connection,
        options.page_size,
    )
    .await?;

    repo::fetch_or_clone(temp_dir, repo_owner, repo_name).await?;
    repo::write_commit_graph(temp_dir).await?;
    let repo = gix::open(temp_dir)?;

    let repo_references = repo.references()?;
    let branches = find_tracked_branches(&repo_references, branch_patterns)?;
    for (branch_name, head) in branches {
        update_landings(db_connection, &repo, branch_name, head).await?;
    }

    Ok(())
}

async fn update_prs(
    github_api_token: &str,
    repo_owner: &str,
    repo_name: &str,
    db_connection: &mut pr_tracker_store::PgConnection,
    page_size: u32,
) -> anyhow::Result<()> {
    let github_client = GitHub::new(github_api_token)?;

    loop {
        let cursor = pr_tracker_store::GithubPrQueryCursor::get(db_connection).await?;
        let (pulls, next_page_cursor) = github_client
            .query_pull_requests(repo_owner, repo_name, cursor, page_size)
            .await?;

        for pull_request in pulls {
            pr_tracker_store::Pr::insert(pull_request, db_connection).await?;
        }

        let Some(next_page_cursor) = next_page_cursor else {
            // We reached the end!
            break;
        };
        pr_tracker_store::GithubPrQueryCursor::upsert(&next_page_cursor, db_connection).await?;
    }

    Ok(())
}

fn find_tracked_branches<'a>(
    references: &'a gix::reference::iter::Platform<'_>,
    matchers: &[wildmatch::WildMatch],
) -> anyhow::Result<Vec<(String, gix::Id<'a>)>> {
    references
        // Calling local_branches in a bare repo results in remote branches
        .local_branches()?
        .map(|r| r.map_err(|e| anyhow::anyhow!(e)))
        .map_ok(|branch| (branch.name().shorten().to_string(), branch.id()))
        .filter_ok(|(branch_name, _id)| matchers.iter().any(|matcher| matcher.matches(branch_name)))
        .collect()
}

async fn update_landings(
    db_connection: &mut pr_tracker_store::PgConnection,
    repo: &gix::Repository,
    branch: String,
    head: gix::Id<'_>,
) -> anyhow::Result<()> {
    let branch = pr_tracker_store::Branch::get_or_insert(db_connection, branch).await?;

    for commit in repo.rev_walk([head]).all()? {
        let commit = commit?;

        if let Some(pr) =
            pr_tracker_store::Pr::for_commit(db_connection, commit.id.to_string()).await?
        {
            let landing = pr_tracker_store::Landing {
                github_pr: pr.number,
                branch_id: branch.id(),
            };

            landing.insert(db_connection).await?;
        }
    }

    Ok(())
}
