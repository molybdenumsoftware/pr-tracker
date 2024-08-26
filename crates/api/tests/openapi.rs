#[path = "../test-util.rs"]
mod test_util;

use pr_tracker_api::ApiDoc;
use rocket::futures::FutureExt;
use test_util::TestContext;

#[derive(serde::Deserialize)]
struct Task {
    id: usize,
    complete: bool,
    text: String,
}

#[tokio::test]
async fn openapi() {
    TestContext::with(|ctx| {
        async {
            let response = ctx.client.get("/openapi.json").dispatch().await;
            assert_eq!(response.status(), rocket::http::Status::Ok);
            let body = response.into_string().await.unwrap();
            println!("{body}");
        }
        .boxed()
    })
    .await;
}
