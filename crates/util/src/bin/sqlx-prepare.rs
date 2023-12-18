use futures::FutureExt;
use std::process::Command;
use util::DatabaseContext;

#[tokio::main]
async fn main() {
    DatabaseContext::with(|ctx| {
        async {
            let pool = ctx.pool().await.unwrap();
            util::migrate(&pool).await.unwrap();

            let status = Command::new("cargo")
                .args(["sqlx", "prepare", "--database-url"])
                .arg(ctx.db_url())
                .current_dir(env!("STORE_CRATE_PATH"))
                .status()
                .unwrap();

            assert!(status.success());
        }
        .boxed()
    })
    .await;
}
