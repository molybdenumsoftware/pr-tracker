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

    let acceptor = TcpListener::bind(format!("0.0.0.0:{port}"))
        .into_acceptor()
        .await
        .unwrap();

    sd_notify::notify(true, &[sd_notify::NotifyState::Ready]).unwrap(); //<<< TODO: give a nicer error message ("failed to notify systemd that this service is ready: {err}");

    Server::new_with_acceptor(acceptor)
        .run(app(&db_url).await.unwrap()) // TODO unwrap?
        .await
        .unwrap();
}
