use anyhow::Context;
use graphql_client::GraphQLQuery;

const API_URL: &str = "https://api.github.com/graphql";

#[derive(derive_more::Deref)]
pub struct GitHub(reqwest::Client);

type DateTime = chrono::DateTime<chrono::Utc>;
type GitObjectID = String;

#[derive(Debug, GraphQLQuery)]
#[graphql(
    schema_path = "src/graphql/schema.graphql",
    query_path = "src/graphql/pulls.graphql",
    response_derives = "Debug",
    variables_derives = "Clone,Debug"
)]
pub struct PullsQuery;

impl GitHub {
    pub fn new(api_token: &str) -> anyhow::Result<Self> {
        let mut headers = reqwest::header::HeaderMap::new();
        headers.insert(
            reqwest::header::AUTHORIZATION,
            format!("Bearer {api_token}").parse()?,
        );

        let client = reqwest::Client::builder()
            .user_agent(format!(
                "{}/{}",
                env!("CARGO_PKG_NAME"),
                env!("CARGO_PKG_VERSION")
            ))
            .default_headers(headers)
            .build()?;

        Ok(Self(client))
    }

    pub async fn query_pull_requests(
        &self,
        repo_owner: &str,
        repo_name: &str,
        cursor: Option<pr_tracker_store::GithubPrQueryCursor>,
        page_size: u32,
    ) -> anyhow::Result<(
        Vec<pr_tracker_store::Pr>,
        Option<pr_tracker_store::GithubPrQueryCursor>,
    )> {
        let query_vars = pulls_query::Variables {
            owner: repo_owner.to_owned(),
            name: repo_name.to_owned(),
            cursor: cursor.map(|cursor| cursor.as_str().to_string()),
            page_size: page_size.into(),
        };
        let resp =
            graphql_client::reqwest::post_graphql::<PullsQuery, _>(self, API_URL, query_vars)
                .await?;

        dbg!(&resp); //<<<
        let data = resp.data.context("response with no data")?;

        log::info!("rate limits: {:?}", data.rate_limit);

        let repository = data.repository.context("data with no repo")?;
        let response_prs = repository.pull_requests;
        let nodes = response_prs.nodes.unwrap_or_default();

        let prs = nodes
            .into_iter()
            .map(|node| -> anyhow::Result<_> {
                let node = node.context("null PR node")?;

                let commit = node
                    .merge_commit
                    .map(|commit| pr_tracker_store::GitCommit(commit.oid));

                let number = pr_tracker_store::PrNumber(
                    node.number
                        .try_into()
                        .expect("how many PRs can a repo have?"),
                );

                Ok(pr_tracker_store::Pr { number, commit })
            })
            .collect::<anyhow::Result<Vec<_>>>()?;

        let new_cursor = response_prs
            .page_info
            .end_cursor
            .map(pr_tracker_store::GithubPrQueryCursor::new);

        Ok((prs, new_cursor))
    }
}
