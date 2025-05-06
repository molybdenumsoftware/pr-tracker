#[path = "../test-util.rs"]
#[macro_use]
mod test_util;

use poem::http::StatusCode;
use test_util::TestContext;

#[tokio::test]
async fn healthcheck_ok() {
    TestContext::with(async |ctx| {
        let response = ctx.client().get("/api/v2/healthcheck").send().await;
        response.assert_status_is_ok();
    })
    .await;
}

#[tokio::test]
async fn healthcheck_not_ok() {
    TestContext::with(async |mut ctx| {
        ctx.db_mut().kill_db().unwrap();
        let response = ctx.client().get("/api/v2/healthcheck").send().await;
        response.assert_status(StatusCode::SERVICE_UNAVAILABLE);
    })
    .await;
}
