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
    assert_eq!(2, 3); //<<<
}
