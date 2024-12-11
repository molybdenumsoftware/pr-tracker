use fragile_child::{FragileChild, SpawnFragileChild};
use futures::future::LocalBoxFuture;
use sqlx::{Connection, PgConnection, PgPool};
use std::fs::{create_dir_all, OpenOptions};
use std::os::unix::net::UnixDatagram;
use std::{process::Command, time::Duration};
use tempfile::{tempdir, TempDir};

use camino::{Utf8Path, Utf8PathBuf};

#[derive(Copy, Clone, Debug)]
pub enum LogDestination {
    File,
    Inherit,
}

pub struct DatabaseContext {
    tmp_dir: TempDir,
    postgres: FragileChild,
}

impl DatabaseContext {
    // Will not be used as port, but as part of socket filename.
    // See `listen_addresses` below.
    const PORT: &'static str = "1";

    pub async fn connection(&self) -> Result<PgConnection, sqlx::Error> {
        let url = self.db_url();
        PgConnection::connect(&url).await
    }

    fn sockets_dir(path: &Utf8Path) -> Utf8PathBuf {
        path.join("sockets")
    }

    pub async fn pool(&self) -> Result<PgPool, sqlx::Error> {
        let url = self.db_url();
        PgPool::connect(&url).await
    }

    async fn init(log_destination: LogDestination) -> Self {
        let tmp_dir = tempdir().unwrap();
        let sockets_dir = Self::sockets_dir(tmp_dir.path().try_into().unwrap());
        let data_dir = tmp_dir.path().join("data");
        std::fs::create_dir(&sockets_dir).unwrap();

        let mut initdb = Command::new(env!("POSTGRESQL_INITDB"));
        let mut postgres = Command::new(env!("POSTGRESQL_POSTGRES"));

        match log_destination {
            LogDestination::File => {
                let repo = gix::discover(".").unwrap();
                let repo_root: Utf8PathBuf =
                    repo.work_dir().unwrap().to_path_buf().try_into().unwrap();
                let path = repo_root.join("logs").join("psql.log");
                println!("Logging to {path}");
                create_dir_all(path.parent().unwrap()).unwrap();

                let log_destination = OpenOptions::new()
                    .create(true)
                    .append(true)
                    .open(path.clone())
                    .unwrap();

                initdb.stdout(log_destination.try_clone().unwrap());
                postgres.stderr(log_destination);
            }
            LogDestination::Inherit => {
                // This is the default behavior for Command.
            }
        }

        let status = initdb.arg(&data_dir).status().unwrap();

        assert!(status.success());

        let ready_socket_path = tmp_dir.path().join("postgresql-ready.sock");
        let ready_socket = UnixDatagram::bind(&ready_socket_path).unwrap();

        let postgres = postgres
            // With this environment variable present, postgres sends a ready notification. This
            // interferes with our testing of our own ready notification.
            .env_remove("NOTIFY_SOCKET")
            // To reliably wait for postgres to be ready.
            .env("NOTIFY_SOCKET", ready_socket_path)
            .arg("-D")
            .arg(data_dir)
            .arg("-p")
            .arg(Self::PORT)
            .arg("-c")
            .arg(format!("unix_socket_directories={sockets_dir}"))
            .arg("-c")
            .arg("listen_addresses=")
            .spawn_fragile()
            .unwrap();

        ready_socket
            .set_read_timeout(Some(Duration::from_secs(5)))
            .unwrap();

        const READY: &[u8] = b"READY=1";
        let mut buf = [0; READY.len()];
        ready_socket.recv(&mut buf).unwrap();
        assert_eq!(buf, READY, "db should start within 5 seconds");

        Self { tmp_dir, postgres }
    }

    pub fn db_url(&self) -> String {
        let dbname = "postgres";

        format!(
            "postgresql:///{dbname}?host={}&port={}",
            Self::sockets_dir(self.tmp_dir.path().try_into().unwrap()),
            Self::PORT,
        )
    }

    pub fn kill_db(&mut self) -> std::io::Result<()> {
        self.postgres.kill()?;
        self.postgres.wait()?;
        Ok(())
    }

    pub async fn with<T>(
        f: impl FnOnce(Self) -> LocalBoxFuture<'static, T>,
        log_destination: LogDestination,
    ) -> T {
        let ctx = Self::init(log_destination).await;
        f(ctx).await
    }
}
