#[path = "../test-util.rs"]
#[macro_use]
mod test_util;

use futures::FutureExt;
use poem::http::StatusCode;
use test_util::TestContext;

test![negative_pr_number, |ctx: TestContext| async move {
    let response = ctx.client().get("/api/v1/-1").send().await;
    response.assert_status(StatusCode::BAD_REQUEST);
    response
        .assert_text("Pull request number non-positive.")
        .await;
}];

// https://github.com/molybdenumsoftware/pr-tracker/issues/241
// async fn bork_db(ctx: &mut db_context::DatabaseContext) {
//     let mut sure = ctx.connection().await.unwrap();
//     sqlx::raw_sql(
//         "
//         ALTER TABLE github_prs DROP COLUMN commit
//         ",
//     )
//     .execute(&mut sure)
//     .await;
// }
//
// test![internal_landed_error, |mut ctx: TestContext| async move {
//     bork_db(ctx.db_mut()).await;
//     let response = ctx.client().get("/api/v1/1").send().await;
//     response.assert_status(StatusCode::SERVICE_UNAVAILABLE);
//     response.assert_text("Error. Sorry.").await;
// }];

test![pr_not_found, |ctx: TestContext| async move {
    let response = ctx.client().get("/api/v1/2134").send().await;
    response.assert_status(StatusCode::NO_CONTENT);
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
