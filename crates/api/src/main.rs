#![warn(clippy::pedantic)]

use anyhow::Context;
use confique::Config;
use poem::{
    listener::{Listener, TcpListener},
    Server,
};
use pr_tracker_api::endpoint;
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

    let addr = format!("0.0.0.0:{port}");
    let acceptor = TcpListener::bind(&addr)
        .into_acceptor()
        .await
        .with_context(|| format!("failed to bind on {addr}"))
        .unwrap();

    sd_notify::notify(true, &[sd_notify::NotifyState::Ready])
        .context("failed to notify systemd that this service is ready")
        .unwrap();

    let endpoint = endpoint(&db_url).await;

    Server::new_with_acceptor(acceptor)
        .run(endpoint)
        .await
        .context("server crashed")
        .unwrap();
}
