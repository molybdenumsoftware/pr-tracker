use db_context::{DatabaseContext, LogDestination};
use std::process::Command;

#[tokio::main]
async fn main() {
    DatabaseContext::with(
        async |ctx| {
            let pool = ctx.pool().await.unwrap();
            util::migrate(&pool).await.unwrap();

            let status = Command::new("cargo")
                .args(["sqlx", "prepare", "--database-url"])
                .arg(ctx.db_url())
                .current_dir(env!("STORE_CRATE_PATH"))
                .status()
                .unwrap();

            assert!(status.success());
        },
        LogDestination::Inherit,
    )
    .await;
}
