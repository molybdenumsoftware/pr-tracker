use db_context::{DatabaseContext, LogDestination};
use std::process::{self, Command};

#[tokio::main]
async fn main() {
    let code = DatabaseContext::with(
        async |database_ctx| {
            let pool = database_ctx.pool().await.unwrap();
            util::migrate(&pool).await.unwrap();
            let db_url = database_ctx.db_url();
            let status = Command::new("psql").arg(db_url).status().unwrap();
            status.code().unwrap()
        },
        LogDestination::File,
    )
    .await;

    process::exit(code)
}
