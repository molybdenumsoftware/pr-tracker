#![warn(clippy::pedantic)]
// required because rocket::launch, remove if clippy permits.
#![allow(clippy::no_effect_underscore_binding)]
#![allow(non_snake_case, clippy::struct_field_names)]

use confique::Config;
use pr_tracker_api::app;
use rocket::{figment::Figment, launch};

#[derive(Debug, Config)]
struct Environment {
    #[config(env = "PR_TRACKER_API_DATABASE_URL")]
    PR_TRACKER_API_DATABASE_URL: String,
    #[config(env = "PR_TRACKER_API_PORT")]
    PR_TRACKER_API_PORT: u16,
}

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
