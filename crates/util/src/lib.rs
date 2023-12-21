use fragile_child::{FragileChild, SpawnFragileChild};
use sqlx::Connection;
use std::ops::Deref;
use std::process::Command;
use std::time::{Duration, Instant};

use camino::{Utf8Path, Utf8PathBuf};
use sqlx::PgPool;

pub struct DatabaseContext {
    tmp_dir: tempfile::TempDir,
    postgres: FragileChild,
}

pub async fn migrate<'a, A>(migrator: A) -> Result<(), sqlx::migrate::MigrateError>
where
    A: sqlx::Acquire<'a>,
    <A::Connection as Deref>::Target: sqlx::migrate::Migrate,
{
    sqlx::migrate!("./migrations").run(migrator).await
}

impl DatabaseContext {
    // Will not be used as port, but as part of socket filename.
    // See `listen_addresses` below.
    const PORT: &'static str = "1";

    pub async fn connection(&self) -> Result<sqlx::PgConnection, sqlx::Error> {
        let url = self.db_url();
        sqlx::PgConnection::connect(&url).await
    }

    fn sockets_dir(path: &Utf8Path) -> Utf8PathBuf {
        path.join("sockets")
    }

    pub async fn pool(&self) -> Result<PgPool, sqlx::Error> {
        let url = self.db_url();
        sqlx::PgPool::connect(&url).await
    }

    async fn init() -> Self {
        let tmp_dir = tempfile::tempdir().unwrap();
        let sockets_dir = Self::sockets_dir(tmp_dir.path().try_into().unwrap());
        let data_dir = tmp_dir.path().join("data");
        std::fs::create_dir(&sockets_dir).unwrap();

        let status = Command::new("initdb").arg(&data_dir).status().unwrap();

        assert!(status.success());

        let postgres = Command::new("postgres")
            // With this environment variable present, postgres sends a ready notification. This
            // interferes with our testing of our own ready notification.
            .env_remove("NOTIFY_SOCKET")
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

        let socket_path = sockets_dir.join(format!(".s.PGSQL.{}", Self::PORT));
        let started = Instant::now();

        while !socket_path.exists() {
            assert!(
                started.elapsed() < Duration::from_secs(5),
                "db should start within 5 seconds"
            );
            std::thread::sleep(Duration::from_millis(10));
        }

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

    pub async fn with<T>(f: impl FnOnce(&mut Self) -> futures::future::LocalBoxFuture<T>) -> T {
        let mut ctx = Self::init().await;
        let t = f(&mut ctx).await;
        drop(ctx);
        t
    }
}
