use camino::Utf8PathBuf;
use db_context::{DatabaseContext, LogDestination};
use itertools::Itertools;
use pr_tracker_store::{Branch, GitCommit, GithubPrQueryCursor, Landing, Pr, PrNumber};
use tempfile::TempDir;
use wildmatch::WildMatch;

use crate::{github::GithubClient, repo::isolated_git};
use std::collections::BTreeSet;

static LOGGER: std::sync::LazyLock<()> = std::sync::LazyLock::new(|| {
    env_logger::init();
});

macro_rules! assert_landings {
    ($ctx:expr, $expected:expr) => {
        let mut connection = $ctx.db_context.connection().await.unwrap();

        let landings = Landing::all(&mut connection).await.unwrap();
        let all_branches = Branch::all(&mut connection).await.unwrap();

        let actual = landings
            .into_iter()
            .map(|landing| {
                (
                    i32::from(landing.github_pr),
                    all_branches.get(&landing.branch_id).unwrap().name(),
                )
            })
            .sorted()
            .collect_vec();

        let expected = $expected
            .into_iter()
            .map(|(pr, branch_name): (&MockPr, &str)| (i32::from(pr.number), branch_name))
            .collect_vec();

        assert_eq!(actual, expected);
    };
}

macro_rules! assert_prs {
    ($ctx:expr, $expected:expr) => {
        let mut connection = $ctx.db_context.connection().await.unwrap();

        let prs = Pr::all(&mut connection).await.unwrap();

        let actual = prs
            .into_iter()
            .map(|pr| i32::from(pr.number))
            .sorted()
            .collect_vec();

        let expected = $expected
            .into_iter()
            .map(|pr: &MockPr| i32::from(pr.number))
            .collect_vec();

        assert_eq!(actual, expected);
    };
}

macro_rules! assert_queried_cursors {
    ($ctx:expr, $expected:expr) => {
        let expected = $expected
            .into_iter()
            .map(|pr: Option<&MockPr>| pr.map(MockPr::cursor))
            .collect_vec();
        assert_eq!($ctx.queried_cursors, expected);
    };
}

#[derive(Debug, Clone)]
struct MockPr {
    number: PrNumber,
    target_branch: &'static str,
    mtime: u32,
    commit: Option<String>,
}

impl PartialEq for MockPr {
    fn eq(&self, other: &Self) -> bool {
        self.number == other.number
    }
}

impl Eq for MockPr {}

impl Ord for MockPr {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        self.mtime.cmp(&other.mtime)
    }
}

impl PartialOrd for MockPr {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        Some(self.cmp(other))
    }
}

impl MockPr {
    fn cursor(&self) -> GithubPrQueryCursor {
        GithubPrQueryCursor::new(self.mtime.to_string())
    }
}

struct TestContext {
    db_context: DatabaseContext,
    tempdir: TempDir,
    pull_requests: BTreeSet<MockPr>,
    pull_request_mtime_counter: u32,
    remote_repo_path: Utf8PathBuf,
    page_size: usize,
    queried_cursors: Vec<Option<GithubPrQueryCursor>>,
}

impl TestContext {
    async fn with(test: impl AsyncFnOnce(TestContext)) {
        std::sync::LazyLock::force(&LOGGER);

        DatabaseContext::with(
            async |db_context| {
                let tempdir = tempfile::tempdir().unwrap();

                let remote_repo_path =
                    Utf8PathBuf::try_from(tempdir.path().join("remote-repo")).unwrap();

                isolated_git(["init", remote_repo_path.as_str(), "--initial-branch=main"])
                    .await
                    .unwrap();

                let test_context = TestContext {
                    db_context,
                    tempdir,
                    pull_requests: BTreeSet::new(),
                    pull_request_mtime_counter: 0,
                    remote_repo_path,
                    page_size: usize::MAX,
                    queried_cursors: Vec::new(),
                };

                test_context
                    .isolated_git(["commit", "--allow-empty", "-m", "init"])
                    .await;

                test(test_context).await;
            },
            LogDestination::Inherit,
        )
        .await;
    }

    async fn run(&mut self, branch_patterns: &[WildMatch]) {
        let mut connection = self.db_context.connection().await.unwrap();
        let repo_dir = self.repo_dir();
        crate::run(&mut connection, self, &repo_dir, branch_patterns)
            .await
            .unwrap();
    }

    fn repo_dir(&self) -> Utf8PathBuf {
        self.tempdir.path().join("repo").try_into().unwrap()
    }

    async fn isolated_git(&self, args: impl IntoIterator<Item = &str>) -> String {
        let args = ["-C", self.remote_repo_path.as_str()]
            .into_iter()
            .chain(args.into_iter().collect_vec());

        let output = isolated_git(args).await.unwrap();
        String::from_utf8(output.stdout).unwrap()
    }

    async fn create_branch(&mut self, name: &str, start_point: &str) {
        self.isolated_git(["branch", name, start_point]).await;
    }

    fn pr_against(&mut self, target_branch: &'static str) -> MockPr {
        let mtime = self.pull_request_mtime_counter;
        self.pull_request_mtime_counter += 1;

        let number = self.pull_requests.len() + 1;
        let number = number.try_into().unwrap();

        let pr = MockPr {
            number,
            target_branch,
            mtime,
            commit: None,
        };

        self.pull_requests.insert(pr.clone());

        pr
    }

    async fn merge_pr(&mut self, pr: &MockPr) -> String {
        let pr = self
            .pull_requests
            .iter()
            .find(|other_pr| other_pr.number == pr.number)
            .unwrap()
            .clone();

        self.pull_requests.remove(&pr);

        let mtime = self.pull_request_mtime_counter;
        self.pull_request_mtime_counter += 1;

        self.isolated_git(["switch", pr.target_branch]).await;

        let number: i32 = pr.number.into();
        self.isolated_git([
            "commit",
            "--allow-empty",
            "-m",
            format!("Merge PR {number}").as_str(),
        ])
        .await;

        let commit = self
            .isolated_git(["rev-parse", "HEAD"])
            .await
            .trim()
            .to_owned();

        let pr = MockPr {
            mtime,
            commit: Some(commit.clone()),
            ..pr
        };

        self.pull_requests.insert(pr);

        commit
    }

    async fn merge_branch_into_branch(&mut self, branch: &'static str, into: &'static str) {
        self.isolated_git(["switch", into]).await;
        self.isolated_git(["merge", branch]).await;
    }

    async fn rebase_branch_on_branch(&mut self, branch: &'static str, base: &'static str) {
        self.isolated_git(["rebase", branch, "--onto", base]).await;
    }

    fn set_github_client_page_size(&mut self, page_size: usize) {
        self.page_size = page_size;
    }
}

impl GithubClient for &mut TestContext {
    async fn query_pull_requests(
        &mut self,
        cursor: Option<GithubPrQueryCursor>,
    ) -> anyhow::Result<(Vec<Pr>, Option<GithubPrQueryCursor>)> {
        self.queried_cursors.push(cursor.clone());

        let cursor_mtime: u32 = cursor
            .map(|cursor| cursor.as_str().parse().unwrap())
            .unwrap_or_default();

        let mut pull_requests_since = self
            .pull_requests
            .iter()
            .skip_while(|pr| cursor_mtime > pr.mtime);

        let page = pull_requests_since
            .by_ref()
            .take(self.page_size)
            .map(|pr| Pr {
                number: pr.number,
                commit: pr.commit.clone().map(GitCommit),
            })
            .collect_vec();

        let cursor = pull_requests_since.next().map(MockPr::cursor);

        Ok((page, cursor))
    }

    fn remote(&self) -> String {
        self.remote_repo_path.to_string()
    }
}

#[tokio::test]
async fn story() {
    TestContext::with(async |mut context| {
        let branch_patterns = &[WildMatch::new("*")];

        context.run(branch_patterns).await;
        assert_prs!(context, &[]);
        assert_landings!(context, []);

        let pr_1 = &context.pr_against("main");
        context.run(branch_patterns).await;
        assert_prs!(context, [pr_1]);
        assert_landings!(context, []);

        context.merge_pr(pr_1).await;
        context.run(branch_patterns).await;
        assert_prs!(context, [pr_1]);
        assert_landings!(context, [(pr_1, "main")]);

        // idempotency
        context.run(branch_patterns).await;
        assert_prs!(context, [pr_1]);
        assert_landings!(context, [(pr_1, "main")]);

        let pr_2 = &context.pr_against("main");
        context.run(branch_patterns).await;
        assert_prs!(context, [pr_1, pr_2]);
        assert_landings!(context, [(pr_1, "main")]);

        context.create_branch("staging", "main").await;
        let pr_3 = &context.pr_against("staging");
        context.run(branch_patterns).await;
        assert_prs!(context, [pr_1, pr_2, pr_3]);
        assert_landings!(context, [(pr_1, "main"), (pr_1, "staging")]);

        context.merge_pr(pr_3).await;
        context.run(branch_patterns).await;
        assert_prs!(context, [pr_1, pr_2, pr_3]);
        assert_landings!(
            context,
            [(pr_1, "main"), (pr_1, "staging"), (pr_3, "staging")]
        );

        context.merge_branch_into_branch("staging", "main").await;
        context.run(branch_patterns).await;
        assert_prs!(context, [pr_1, pr_2, pr_3]);
        assert_landings!(
            context,
            [
                (pr_1, "main"),
                (pr_1, "staging"),
                (pr_3, "main"),
                (pr_3, "staging")
            ]
        );

        let pr_4 = &context.pr_against("main");
        context.merge_pr(pr_4).await;
        let pr_5 = &context.pr_against("main");
        context.merge_pr(pr_5).await;
        let pr_6 = &context.pr_against("staging");
        context.merge_pr(pr_6).await;
        context.run(branch_patterns).await;
        assert_prs!(context, [pr_1, pr_2, pr_3, pr_4, pr_5, pr_6]);
        assert_landings!(
            context,
            [
                (pr_1, "main"),
                (pr_1, "staging"),
                (pr_3, "main"),
                (pr_3, "staging"),
                (pr_4, "main"),
                (pr_5, "main"),
                (pr_6, "staging"),
            ]
        );

        context.rebase_branch_on_branch("staging", "main").await;
        context.run(branch_patterns).await;
        assert_landings!(
            context,
            [
                (pr_1, "main"),
                (pr_1, "staging"),
                (pr_3, "main"),
                (pr_3, "staging"),
                (pr_4, "main"),
                (pr_4, "staging"),
                (pr_5, "main"),
                (pr_5, "staging"),
                (pr_6, "staging"),
            ]
        );
    })
    .await;
}

#[tokio::test]
async fn branch_patterns() {
    TestContext::with(async |mut context| {
        context.create_branch("release-1", "main").await;
        context.create_branch("release-10", "main").await; // for the asterisk
        let pr_1 = &context.pr_against("main");
        context.merge_pr(pr_1).await;
        let pr_2 = &context.pr_against("release-1");
        context.merge_pr(pr_2).await;
        let pr_3 = &context.pr_against("release-10");
        context.merge_pr(pr_3).await;
        context.run(&[WildMatch::new("main")]).await;
        assert_prs!(context, [pr_1, pr_2, pr_3]);
        assert_landings!(context, [(pr_1, "main")]);

        context
            .run(&[WildMatch::new("main"), WildMatch::new("release-*")])
            .await;

        assert_landings!(
            context,
            [(pr_1, "main"), (pr_2, "release-1"), (pr_3, "release-10")]
        );
    })
    .await;
}

#[tokio::test]
async fn github_client_pagination() {
    TestContext::with(async |mut context| {
        let branch_patterns = [WildMatch::new("main")];
        let pr_1 = &context.pr_against("main");
        let pr_2 = &context.pr_against("main");
        let pr_3 = &context.pr_against("main");
        let pr_4 = &context.pr_against("main");
        let pr_5 = &context.pr_against("main");
        context.set_github_client_page_size(2);
        context.run(&branch_patterns).await;
        assert_prs!(context, [pr_1, pr_2, pr_3, pr_4, pr_5]);
        assert_queried_cursors!(
            context,
            [
                None,       // returns pr_1, pr_2 and cursor to pr_3
                Some(pr_3), // returns pr_3, pr_4 and cursor to pr_5
                Some(pr_5), // returns pr_5 and no cursor
            ]
        );

        let pr_6 = &context.pr_against("main");
        context.run(&branch_patterns).await;
        assert_prs!(context, [pr_1, pr_2, pr_3, pr_4, pr_5, pr_6]);
        assert_queried_cursors!(
            context,
            [
                None,       // as documented above
                Some(pr_3), // as documented above
                Some(pr_5), // as documented above
                Some(pr_5), // returns pr_5, pr_6 and no cursor
            ]
        );
    })
    .await;
}
