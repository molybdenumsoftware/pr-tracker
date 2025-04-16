#[path = "../test-util.rs"]
#[macro_use]
mod test_util;

use futures::FutureExt;
use test_util::TestContext;

test![json, |ctx: TestContext| async move {
    let response = ctx.client().get("/openapi.json").send().await;
    response.assert_status_is_ok();
    let json = response.json().await;
    dbg!(json);
}];

//<<<
test![json, |ctx: TestContext| async move {
    let response = ctx.client().get("/openapi.json").send().await;
    response.assert_status_is_ok();
    let json = response.json().await;
    dbg!(json);
}];
