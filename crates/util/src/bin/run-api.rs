use clap::Parser;
use db_context::{DatabaseContext, LogDestination};
use futures::FutureExt;
use std::process::{self, Command};

#[derive(Parser, Debug)]
struct Cli {
    #[arg(short, long, default_value_t = 8080)]
    port: u16,
}

#[tokio::main]
async fn main() {
    let args = Cli::parse();

    let code = DatabaseContext::with(
        |database_ctx| {
            async move {
                let pool = database_ctx.pool().await.unwrap();
                util::migrate(&pool).await.unwrap();
                let status = Command::new("cargo")
                    .args(["run", "--package", "pr-tracker-api"])
                    .env("PR_TRACKER_API_DATABASE_URL", database_ctx.db_url())
                    .env("PR_TRACKER_API_PORT", args.port.to_string())
                    .status()
                    .unwrap();
                status.code().unwrap()
            }
            .boxed()
        },
        LogDestination::File,
    )
    .await;

    process::exit(code)
}
