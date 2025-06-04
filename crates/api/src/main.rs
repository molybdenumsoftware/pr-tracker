#![warn(clippy::pedantic)]

mod config;

use anyhow::Context;
use config::Environment;
use confique::Config;
use poem::{
    Server,
    listener::{Listener, TcpListener},
};
use pr_tracker_api::endpoint;

#[tokio::main]
async fn main() {
    let config = Environment::builder()
        .env()
        .load()
        .expect("loading configuration from environment");

    let Environment {
        PR_TRACKER_API_DATABASE_URL: db_url,
        PR_TRACKER_API_PORT: port,
        PR_TRACKER_TRACING_FILTER: tracing_filter,
    } = config;

    tracing_subscriber::fmt()
        .with_env_filter(tracing_filter.unwrap_or_default().env_filter)
        .init();

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
