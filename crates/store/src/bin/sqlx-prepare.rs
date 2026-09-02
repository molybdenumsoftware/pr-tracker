use db_context::{DatabaseContext, LogDestination};
use std::process::Command;

#[tokio::main]
async fn main() {
    DatabaseContext::with(
        async |ctx| {
            let pool = ctx.pool().await.unwrap();
            util::migrate(&pool).await.unwrap();

            let status = Command::new("sqlx")
                .args(["prepare", "--database-url"])
                .arg(ctx.db_url())
                .current_dir(env!("CARGO_MANIFEST_DIR"))
                .status()
                .unwrap();

            assert!(status.success());
        },
        LogDestination::Inherit,
    )
    .await;
}
