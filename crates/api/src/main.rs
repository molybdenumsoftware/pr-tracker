#![warn(clippy::pedantic)]

use confique::Config;
use poem::listener::TcpListener;
use pr_tracker_api::app;
use pr_tracker_api_config::Environment;

#[tokio::main]
async fn main() {
    let config = Environment::builder()
        .env()
        .load()
        .expect("loading configuration from environment");

    let Environment {
        PR_TRACKER_API_DATABASE_URL: db_url,
        PR_TRACKER_API_PORT: port,
    } = config;

    Server::new(TcpListener::bind(format!("0.0.0.0:{port}")))
        .run(app())
        .await
}
