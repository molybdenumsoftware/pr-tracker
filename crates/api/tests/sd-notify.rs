use db_context::DatabaseContext;
use fragile_child::SpawnFragileChild;
use futures::{self, FutureExt};
use std::process::Command;

#[tokio::test]
async fn notifies() {
    let api_exe = env!("CARGO_BIN_EXE_pr-tracker-api");

    let temp_dir = tempfile::tempdir().unwrap();
    let socket_path = temp_dir.path().join("notify-socket");
    let sock = std::os::unix::net::UnixDatagram::bind(&socket_path).unwrap();
    sock.set_read_timeout(Some(std::time::Duration::from_secs(1)))
        .unwrap();
    const EXPECTED: &[u8] = b"READY=1\n";

    DatabaseContext::with(
        move |db_context| {
            async move {
                let mut child = Command::new(api_exe)
                    .env("NOTIFY_SOCKET", &socket_path)
                    .env("PR_TRACKER_API_DATABASE_URL", db_context.db_url())
                    .env("PR_TRACKER_API_PORT", "4242") // Use a socket instead: https://github.com/molybdenumsoftware/pr-tracker/issues/216
                    .spawn_fragile()
                    .unwrap();

                let mut buf = [0; EXPECTED.len()];
                sock.recv(&mut buf).unwrap();
                assert_eq!(buf, EXPECTED);
                child.kill().unwrap();
            }
            .boxed_local()
        },
        db_context::LogDestination::Inherit,
    )
    .await;
}
