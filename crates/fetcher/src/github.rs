use anyhow::Context;
use graphql_client::GraphQLQuery;
use pr_tracker_store::{GitCommit, GithubPrQueryCursor, Pr, PrNumber};
use reqwest::header::HeaderValue;

// https://docs.github.com/en/graphql/overview/rate-limits-and-node-limits-for-the-graphql-api#node-limit
const PAGE_SIZE: i64 = 100;
const API_URL: &str = "https://api.github.com/graphql";
const USER_AGENT: &str = concat!(env!("CARGO_PKG_NAME"), "/", env!("CARGO_PKG_VERSION"));

#[allow(async_fn_in_trait, clippy::module_name_repetitions)]
pub trait GithubClient {
    async fn query_pull_requests(
        &mut self,
        cursor: Option<GithubPrQueryCursor>,
    ) -> anyhow::Result<(Vec<Pr>, Option<GithubPrQueryCursor>)>;

    fn remote(&self) -> String;
}

#[derive(derive_more::Deref)]
pub struct GitHubGraphqlClient {
    #[deref]
    reqwest_client: reqwest::Client,
    repo_owner: String,
    repo_name: String,
    page_size: i64,
}

type DateTime = chrono::DateTime<chrono::Utc>;
type GitObjectID = String;

#[derive(Debug, GraphQLQuery)]
#[graphql(
    schema_path = "src/graphql/schema.graphql",
    query_path = "src/graphql/pulls.graphql",
    response_derives = "Debug",
    variables_derives = "Clone, Debug"
)]
pub struct PullsQuery;

impl GitHubGraphqlClient {
    /// Construct a client to speak to github.com.
    ///
    /// # Errors
    ///
    /// Lots of stuff. Read the code for details.
    pub fn new(
        api_token: &str,
        repo_owner: String,
        repo_name: String,
        page_size_override_for_testing: Option<i64>,
    ) -> anyhow::Result<Self> {
        let mut headers = reqwest::header::HeaderMap::new();
        let mut authorization = HeaderValue::from_str(&format!("Bearer {api_token}"))?;
        authorization.set_sensitive(true);
        headers.insert(reqwest::header::AUTHORIZATION, authorization);

        let client = reqwest::Client::builder()
            .user_agent(USER_AGENT)
            .default_headers(headers)
            .build()?;

        Ok(Self {
            reqwest_client: client,
            repo_owner,
            repo_name,
            page_size: page_size_override_for_testing.unwrap_or(PAGE_SIZE),
        })
    }
}

impl GithubClient for GitHubGraphqlClient {
    async fn query_pull_requests(
        &mut self,
        cursor: Option<GithubPrQueryCursor>,
    ) -> anyhow::Result<(Vec<Pr>, Option<GithubPrQueryCursor>)> {
        let query_vars = pulls_query::Variables {
            owner: self.repo_owner.clone(),
            name: self.repo_name.clone(),
            cursor: cursor.map(|cursor| cursor.as_str().to_string()),
            page_size: self.page_size,
        };

        let body = PullsQuery::build_query(query_vars);
        let request = self.post(API_URL).json(&body);
        log::info!("request: {request:#?}");
        log::info!("request body: {body:#?}");
        let resp: graphql_client::Response<pulls_query::ResponseData> =
            request.send().await?.json().await?;

        // https://github.com/graphql-rust/graphql-client/issues/467
        let data = resp
            .data
            .as_ref()
            .context("response with no data, this might be due to an expired token")?;

        log::info!("rate limits: {:?}", data.rate_limit);

        let repository = data
            .repository
            .as_ref()
            .context(format!("data with no repo\n{:#?}", &resp))?;
        let nodes = repository
            .pull_requests
            .nodes
            .as_deref()
            .unwrap_or_default();

        let prs = nodes
            .iter()
            .map(|node| -> anyhow::Result<_> {
                let node = node.as_ref().context("null PR node")?;

                let commit = node
                    .merge_commit
                    .as_ref()
                    .map(|commit| GitCommit(commit.oid.clone()));

                let number: PrNumber = node
                    .number
                    .try_into()
                    .expect("how many PRs can a repo have?");

                Ok(Pr { number, commit })
            })
            .collect::<anyhow::Result<Vec<_>>>()?;

        let new_cursor = repository
            .pull_requests
            .page_info
            .end_cursor
            .clone()
            .map(GithubPrQueryCursor::new);

        Ok((prs, new_cursor))
    }

    fn remote(&self) -> String {
        let Self {
            repo_owner,
            repo_name,
            ..
        } = &self;

        format!("https://github.com/{repo_owner}/{repo_name}")
    }
}

#[cfg(feature = "impure_tests")]
#[cfg(test)]
mod test {
    use super::*;

    #[tokio::test]
    async fn pagination() {
        let github_token = std::env::var("GITHUB_TOKEN").expect("$GITHUB_TOKEN should be set");
        let repo_owner = "molybdenumsoftware".to_owned();
        let repo_name = "pr-tracker".to_owned();
        let page_size = 2;
        let mut github_client =
            GitHubGraphqlClient::new(&github_token, repo_owner, repo_name, Some(page_size))
                .unwrap();

        let expected_prs = [
            Pr {
                number: 11.try_into().unwrap(),
                commit: Some("d9fb7b575ecf12bcad8fe2a8d6c954f65eda9a66".into()),
            },
            Pr {
                number: 4.try_into().unwrap(),
                commit: None,
            },
            Pr {
                number: 6.try_into().unwrap(),
                commit: Some("e611c3a218e2a1cf9f9cf72fb2d8537656c10210".into()),
            },
            Pr {
                number: 5.try_into().unwrap(),
                commit: Some("40277c59c6da324cb2e0d83bb1f8e496804dd8bc".into()),
            },
        ];

        let cursor = None;
        let (prs, cursor) = github_client.query_pull_requests(cursor).await.unwrap();

        assert_eq!(prs, &expected_prs[..2]);

        let (prs, _) = github_client.query_pull_requests(cursor).await.unwrap();

        assert_eq!(prs, &expected_prs[2..4]);
    }

    #[tokio::test]
    async fn finite_pagination() {
        let github_token = std::env::var("GITHUB_TOKEN").expect("$GITHUB_TOKEN should be set");
        let repo_owner = "molybdenumsoftware".to_owned();
        let repo_name = "pr-tracker".to_owned();
        let mut github_client =
            GitHubGraphqlClient::new(&github_token, repo_owner, repo_name, None).unwrap();

        let mut cursor = None;
        for _ in 0..10000 {
            cursor = github_client.query_pull_requests(cursor).await.unwrap().1;
            if cursor.is_none() {
                // Success: Found the end.
                return;
            }
        }

        panic!("pagination was not finite (or repo is too popular)");
    }
}
