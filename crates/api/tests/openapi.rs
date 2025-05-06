#[path = "../test-util.rs"]
#[macro_use]
mod test_util;

use poem::http::StatusCode;
use test_util::TestContext;

#[tokio::test]
async fn json() {
    TestContext::with(async |ctx| {
        let response = ctx.client().get("/openapi.json").send().await;
        response.assert_status_is_ok();
        response.assert_content_type("application/json");
    })
    .await;
}

#[tokio::test]
async fn homepage_redirect() {
    TestContext::with(async |ctx| {
        let response = ctx.client().get("/").send().await;
        response.assert_status(StatusCode::SEE_OTHER);
        response.assert_header("Location", "/api-docs");
    })
    .await;
}

#[tokio::test]
async fn api_docs() {
    TestContext::with(async |ctx| {
        let response = ctx.client().get("/api-docs").send().await;
        response.assert_status_is_ok();
        response.assert_content_type("text/html; charset=utf-8");
    })
    .await;
}
