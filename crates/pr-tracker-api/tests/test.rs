#[path = "../test-util.rs"]
mod test_util;

use rocket::futures::FutureExt;
use test_util::TestContext;

#[tokio::test]
async fn healthcheck_ok() {
    TestContext::with(|ctx| {
        async {
            let response = ctx.client.get("/api/v1/healthcheck").dispatch().await;
            assert_eq!(response.status(), rocket::http::Status::Ok);
        }
        .boxed()
    })
    .await;
}

#[tokio::test]
async fn healthcheck_not_ok() {
    TestContext::with(|ctx| {
        async {
            ctx.db.kill_db().unwrap();
            let response = ctx.client.get("/api/v1/healthcheck").dispatch().await;
            assert_eq!(response.status(), rocket::http::Status::ServiceUnavailable);
        }
        .boxed()
    })
    .await;
}

#[tokio::test]
async fn pr_not_found() {
    TestContext::with(|ctx| {
        async {
            let response = ctx.client.get("/api/v1/2134").dispatch().await;
            assert_eq!(response.status(), rocket::http::Status::NotFound);
            assert_eq!(
                response.into_string().await,
                Some("Pull request not found.".into())
            );
        }
        .boxed()
    })
    .await;
}

#[tokio::test]
async fn pr_not_landed() {
    TestContext::with(|ctx| {
        async {
            let mut connection = ctx.db.connection().await.unwrap();

            pr_tracker_store::Pr {
                number: 123.try_into().unwrap(),
                commit: Some("deadbeef".into()),
            }
            .insert(&mut connection)
            .await
            .unwrap();

            let response = ctx.client.get("/api/v1/123").dispatch().await;
            assert_eq!(response.status(), rocket::http::Status::Ok);

            assert_eq!(
                response
                    .into_json::<pr_tracker_api::LandedIn>()
                    .await
                    .unwrap(),
                pr_tracker_api::LandedIn { branches: vec![] }
            );
        }
        .boxed()
    })
    .await;
}

#[tokio::test]
async fn pr_landed() {
    TestContext::with(|ctx| {
        async {
            let connection = &mut ctx.db.connection().await.unwrap();

            let branch = pr_tracker_store::Branch::get_or_insert(connection, "nixos-unstable")
                .await
                .unwrap();

            let github_pr = pr_tracker_store::Pr {
                number: 2134.into(),
                commit: Some("deadbeef".into()),
            };
            github_pr.clone().insert(connection).await.unwrap();

            let landing = pr_tracker_store::Landing {
                github_pr: github_pr.number,
                branch_id: branch.id(),
            };

            landing.insert(connection).await.unwrap();

            let response = ctx.client.get("/api/v1/2134").dispatch().await;
            assert_eq!(response.status(), rocket::http::Status::Ok);

            assert_eq!(
                response
                    .into_json::<pr_tracker_api::LandedIn>()
                    .await
                    .unwrap(),
                pr_tracker_api::LandedIn {
                    branches: vec![pr_tracker_api::Branch("nixos-unstable".to_owned())]
                }
            );
        }
        .boxed()
    })
    .await;
}
