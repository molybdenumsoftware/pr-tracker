#![warn(clippy::pedantic)]

pub mod github;
mod repo;
#[cfg(test)]
mod test;

use camino::Utf8Path;
use github::GithubClient;
use itertools::Itertools;
use pr_tracker_store::{Branch, GithubPrQueryCursor, Landing, PgConnection, Pr};
use wildmatch::WildMatch;

/// Run the darn thing.
///
/// # Errors
///
/// IO that can fail includes database communication, GraphQL requests and git operations.
pub async fn run(
    db_connection: &mut PgConnection,
    mut github_client: impl GithubClient,
    repo_dir: &Utf8Path,
    branch_patterns: &[WildMatch],
) -> anyhow::Result<()> {
    pr_tracker_store::migrate(&mut *db_connection).await?;

    update_prs(&mut github_client, db_connection).await?;

    let remote = github_client.remote();
    repo::fetch_or_clone(repo_dir, &remote).await?;
    repo::write_commit_graph(repo_dir).await?;
    let repo = gix::open(repo_dir)?;

    let repo_references = repo.references()?;
    let branches = find_tracked_branches(&repo_references, branch_patterns)?;
    for (branch_name, head) in branches {
        update_landings(db_connection, &repo, branch_name, head).await?;
    }

    Ok(())
}

async fn update_prs(
    github_client: &mut impl GithubClient,
    db_connection: &mut PgConnection,
) -> anyhow::Result<()> {
    loop {
        let cursor = GithubPrQueryCursor::get(db_connection).await?;
        let (pulls, next_page_cursor) = github_client.query_pull_requests(cursor).await?;

        for pull_request in pulls {
            Pr::upsert(pull_request, db_connection).await?;
        }

        let Some(next_page_cursor) = next_page_cursor else {
            // We reached the end!
            break;
        };
        GithubPrQueryCursor::upsert(&next_page_cursor, db_connection).await?;
    }

    Ok(())
}

fn find_tracked_branches<'a>(
    references: &'a gix::reference::iter::Platform<'_>,
    matchers: &[WildMatch],
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
    db_connection: &mut PgConnection,
    repo: &gix::Repository,
    branch: String,
    head: gix::Id<'_>,
) -> anyhow::Result<()> {
    let branch = Branch::get_or_insert(db_connection, branch).await?;

    let commits = repo.rev_walk([head]).all()?;

    for commit in commits {
        let commit = commit?;

        if let Some(pr) = Pr::for_commit(db_connection, commit.id.to_string()).await? {
            let landing = Landing {
                github_pr: pr.number,
                branch_id: branch.id(),
            };

            landing.upsert(db_connection).await?;
        }
    }

    Ok(())
}
