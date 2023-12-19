// This test lives all by itself in this file because it sets an environment variable, which
// affects the entire test process.

#[path = "../test-util.rs"]
mod test_util;

use rocket::futures::{self, FutureExt};
use test_util::TestContext;

#[tokio::test]
async fn notifies() {
    let temp_dir = tempfile::tempdir().unwrap();
    let socket_path = temp_dir.path().join("notify-socket");
    std::env::set_var("NOTIFY_SOCKET", &socket_path);
    let sock = std::os::unix::net::UnixDatagram::bind(&socket_path).unwrap();
    sock.set_read_timeout(Some(std::time::Duration::from_secs(1)))
        .unwrap();
    const EXPECTED: &[u8] = b"READY=1\n";

    TestContext::with(move |_| {
        let mut buf = [0; EXPECTED.len()];
        sock.recv(&mut buf).unwrap();
        assert_eq!(buf, EXPECTED);
        futures::future::ready(()).boxed_local()
    })
    .await;
}
