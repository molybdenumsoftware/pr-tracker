#[path = "../test-util.rs"]
mod test_util;

use pr_tracker_api::ApiDoc;
use rocket::futures::FutureExt;
use test_util::TestContext;

#[tokio::test]
async fn openapi() {
    TestContext::with(|ctx| {
        async {
            let response = ctx.client.get("/openapi.json").dispatch().await;
            assert_eq!(response.status(), rocket::http::Status::Ok);
            let response: ApiDoc = response.into_json().await.unwrap();
        }
        .boxed()
    })
    .await;
}
