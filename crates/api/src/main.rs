#![warn(clippy::pedantic)]
// required because rocket::launch, remove if clippy permits.
#![allow(clippy::no_effect_underscore_binding)]

use confique::Config;
use pr_tracker_api::app;
use pr_tracker_api_config::Environment;
use rocket::{figment::Figment, launch};

#[launch]
fn rocket() -> _ {
    let config = Environment::builder()
        .env()
        .load()
        .expect("loading configuration from environment");

    let Environment {
        PR_TRACKER_API_DATABASE_URL: db_url,
        PR_TRACKER_API_PORT: port,
    } = config;

    let figment = Figment::from(rocket::Config::default())
        .merge(("port", port))
        .merge(("databases.data.url", db_url));

    rocket::custom(figment).attach(app())
}
