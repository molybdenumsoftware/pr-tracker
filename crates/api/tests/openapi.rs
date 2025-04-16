#[path = "../test-util.rs"]
#[macro_use]
mod test_util;

use futures::FutureExt;
use poem::http::StatusCode;
use test_util::TestContext;

test![json, |ctx: TestContext| async move {
    let response = ctx.client().get("/openapi.json").send().await;
    response.assert_status_is_ok();
    response.assert_content_type("application/json");
}];

test![homepage_redirect, |ctx: TestContext| async move {
    let response = ctx.client().get("/").send().await;
    response.assert_status(StatusCode::SEE_OTHER);
    response.assert_header("Location", "/api-docs");
}];

test![api_docs, |ctx: TestContext| async move {
    let response = ctx.client().get("/api-docs").send().await;
    response.assert_status_is_ok();
    response.assert_content_type("text/html; charset=utf-8");
}];
