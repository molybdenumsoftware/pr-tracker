#[path = "../test-util.rs"]
#[macro_use]
mod test_util;

use futures::FutureExt;
use poem::http::StatusCode;
use test_util::TestContext;

test![healthcheck_ok, |ctx: TestContext| async move {
    let response = ctx.client().get("/api/v1/healthcheck").send().await;
    response.assert_status_is_ok();
}];

test![healthcheck_not_ok, |mut ctx: TestContext| async move {
    ctx.db_mut().kill_db().unwrap();
    let response = ctx.client().get("/api/v1/healthcheck").send().await;
    response.assert_status(StatusCode::SERVICE_UNAVAILABLE);
}];
