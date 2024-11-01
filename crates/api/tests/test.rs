#[path = "../test-util.rs"]
mod test_util;

use futures::FutureExt;
use poem::http::StatusCode;
use test_util::TestContext;

macro_rules! test {
    ($name:ident, $test:expr) => {
        #[tokio::test]
        async fn $name() {
            TestContext::with(|ctx| async { $test(ctx).await }.boxed()).await;
        }
    };
}

test![healthcheck_ok, |ctx: TestContext| async move {
    let response = ctx.client().get("/api/v1/healthcheck").send().await;
    response.assert_status_is_ok();
}];

test![healthcheck_not_ok, |mut ctx: TestContext| async move {
    ctx.db_mut().kill_db().unwrap();
    let response = ctx.client().get("/api/v1/healthcheck").send().await;
    response.assert_status(StatusCode::SERVICE_UNAVAILABLE);
}];

test![pr_not_found, |ctx: TestContext| async move {
    let response = ctx.client().get("/api/v1/2134").send().await;
    response.assert_status(StatusCode::NOT_FOUND);
    response.assert_text("Pull request not found.").await;
}];

test![pr_not_landed, |ctx: TestContext| async move {
    let mut connection = ctx.db().connection().await.unwrap();

    pr_tracker_store::Pr {
        number: 123.try_into().unwrap(),
        commit: Some("deadbeef".into()),
    }
    .upsert(&mut connection)
    .await
    .unwrap();

    let response = ctx.client().get("/api/v1/123").send().await;
    response.assert_status_is_ok();
    response
        .assert_json(pr_tracker_api::LandedIn { branches: vec![] })
        .await;
}];

test![pr_landed, |ctx: TestContext| async move {
    let connection = &mut ctx.db().connection().await.unwrap();

    let branch = pr_tracker_store::Branch::get_or_insert(connection, "nixos-unstable")
        .await
        .unwrap();

    let github_pr = pr_tracker_store::Pr {
        number: 2134.try_into().unwrap(),
        commit: Some("deadbeef".into()),
    };
    github_pr.clone().upsert(connection).await.unwrap();

    let landing = pr_tracker_store::Landing {
        github_pr: github_pr.number,
        branch_id: branch.id(),
    };

    landing.upsert(connection).await.unwrap();

    let response = ctx.client().get("/api/v1/2134").send().await;
    response.assert_status_is_ok();

    response
        .assert_json(pr_tracker_api::LandedIn {
            branches: vec![pr_tracker_api::Branch("nixos-unstable".to_owned())],
        })
        .await;
}];
