use std::ops::Deref;

use futures::FutureExt;
use pr_tracker_fetcher::Options;

const FIXTURE_REPO_OWNER: &str = "molybdenumsoftware";
const FIXTURE_REPO_NAME: &str = "pr-tracker-test-fixture";

static GITHUB_TOKEN: once_cell::sync::Lazy<String> = once_cell::sync::Lazy::new(|| {
    std::env::var("GITHUB_TOKEN").expect("$GITHUB_TOKEN should be set")
});

static EXPECTED_FIXTURE_PRS: once_cell::sync::Lazy<[pr_tracker_store::Pr; 3]> =
    once_cell::sync::Lazy::new(|| {
        [
            pr_tracker_store::Pr {
                number: pr_tracker_store::PrNumber(1),
                commit: Some(pr_tracker_store::GitCommit(String::from(
                    "73da20569ac857daf6ed4eed70f2f691626b6df3",
                ))),
            },
            pr_tracker_store::Pr {
                number: 2.into(),
                commit: Some("ab909e9f7125283acdd8f6e490ad5b9750f89c81".into()),
            },
            pr_tracker_store::Pr {
                number: 3.into(),
                commit: None,
            },
        ]
    });

static LOGGER: once_cell::sync::Lazy<()> = once_cell::sync::Lazy::new(|| {
    env_logger::init();
});

struct TestContext<'a> {
    db_context: &'a util::DatabaseContext,
    tempdir: tempfile::TempDir,
}

impl TestContext<'_> {
    async fn with(
        test: impl for<'a> FnOnce(&'a TestContext<'a>) -> futures::future::LocalBoxFuture<()> + 'static,
    ) {
        let _ = LOGGER.deref();
        util::DatabaseContext::with(|db_context| {
            async move {
                let tempdir = tempfile::tempdir().unwrap();

                let test_context = TestContext {
                    db_context,
                    tempdir,
                };

                test(&test_context).await;
                drop(test_context);
            }
            .boxed_local()
        })
        .await;
    }

    fn repo_dir(&self) -> camino::Utf8PathBuf {
        self.tempdir.path().join("repo").try_into().unwrap()
    }
}

async fn assert(
    connection: &mut pr_tracker_store::PgConnection,
    expected_landings: &[(i32, &str)],
) {
    let mut landings = pr_tracker_store::Landing::all(connection).await.unwrap();
    landings.sort();
    let all_branches = pr_tracker_store::Branch::all(connection).await.unwrap();

    let actual = landings
        .into_iter()
        .map(|landing| {
            (
                landing.github_pr.0,
                all_branches.get(&landing.branch_id).unwrap().name(),
            )
        })
        .collect::<Vec<_>>();

    assert_eq!(actual, expected_landings);

    let mut prs = pr_tracker_store::Pr::all(connection).await.unwrap();
    prs.sort();

    assert_eq!(prs, *EXPECTED_FIXTURE_PRS);
}

#[tokio::test]
async fn first_run() {
    TestContext::with(|context| {
        async move {
            let mut connection = context.db_context.connection().await.unwrap();

            pr_tracker_fetcher::run(
                &mut connection,
                FIXTURE_REPO_OWNER,
                FIXTURE_REPO_NAME,
                &GITHUB_TOKEN,
                &context.repo_dir(),
                &[
                    wildmatch::WildMatch::new("master"),
                    wildmatch::WildMatch::new("channel*"),
                ],
                &Options::default(),
            )
            .await
            .unwrap();

            assert(
                &mut connection,
                &[(1, "channel1"), (1, "master"), (2, "master")],
            )
            .await;
        }
        .boxed_local()
    })
    .await;
}

#[tokio::test]
async fn subsequent_run() {
    TestContext::with(|context| {
        async move {
            let mut connection = context.db_context.connection().await.unwrap();
            util::migrate(&mut connection).await.unwrap();

            pr_tracker_store::Pr {
                number: 1.into(),
                commit: Some("73da20569ac857daf6ed4eed70f2f691626b6df3".into()),
            }
            .insert(&mut connection)
            .await
            .unwrap();

            pr_tracker_fetcher::run(
                &mut connection,
                FIXTURE_REPO_OWNER,
                FIXTURE_REPO_NAME,
                &GITHUB_TOKEN,
                &context.repo_dir(),
                &[
                    wildmatch::WildMatch::new("master"),
                    wildmatch::WildMatch::new("channel*"),
                ],
                &Options::default(),
            )
            .await
            .unwrap();

            assert(
                &mut connection,
                &[(1, "channel1"), (1, "master"), (2, "master")],
            )
            .await;
        }
        .boxed_local()
    })
    .await;
}

#[tokio::test]
async fn branch_patterns() {
    TestContext::with(|context| {
        async move {
            let mut connection = context.db_context.connection().await.unwrap();

            pr_tracker_fetcher::run(
                &mut connection,
                FIXTURE_REPO_OWNER,
                FIXTURE_REPO_NAME,
                &GITHUB_TOKEN,
                &context.repo_dir(),
                &[wildmatch::WildMatch::new("master")],
                &Options::default(),
            )
            .await
            .unwrap();

            assert(&mut connection, &[(1, "master"), (2, "master")]).await;
        }
        .boxed_local()
    })
    .await;
}
