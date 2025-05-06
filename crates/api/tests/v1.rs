#[path = "../test-util.rs"]
#[macro_use]
mod test_util;

use poem::http::StatusCode;
use test_util::TestContext;

#[tokio::test]
async fn v1_api_not_found() {
    TestContext::with(async |ctx| {
        let response = ctx.client().get("/api/v1/healthcheck").send().await;
        response.assert_status(StatusCode::NOT_FOUND);
        response.assert_text("API v1 not supported").await;

        let response = ctx.client().get("/api/v1/42").send().await;
        response.assert_status(StatusCode::NOT_FOUND);
        response.assert_text("API v1 not supported").await;
    })
    .await;
}
