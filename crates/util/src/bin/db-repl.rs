use futures::FutureExt;
use std::process::{self, Command};
use util::DatabaseContext;

#[tokio::main]
async fn main() {
    // TODO: suppress stdout/stderr from postgres? it's quite annoying when in the psql repl
    let code = DatabaseContext::with(|database_ctx| {
        async {
            let pool = database_ctx.pool().await.unwrap();
            util::migrate(&pool).await.unwrap();
            let db_url = database_ctx.db_url();
            let status = Command::new("psql").arg(db_url).status().unwrap();
            status.code().unwrap()
        }
        .boxed()
    })
    .await;

    process::exit(code)
}
