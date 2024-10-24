#![warn(clippy::pedantic)]

use confique::Config;
use poem::listener::{Listener, TcpListener};
use poem::Server;
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

    let (acceptor, endpoint) = app(port, &db_url).await;

    Server::new_with_acceptor(acceptor)
        .run(endpoint) // TODO unwrap?
        .await
        .unwrap();
}
