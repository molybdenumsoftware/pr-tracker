#![warn(clippy::pedantic)]
// required because rocket::routes, remove if clippy permits.
#![allow(clippy::no_effect_underscore_binding)]

use rocket::{
    futures::FutureExt,
    serde::{Deserialize, Serialize},
};
use rocket_db_pools::{Connection, Database};

async fn run_migrations(rocket: rocket::Rocket<rocket::Build>) -> rocket::fairing::Result {
    let Some(db) = Data::fetch(&rocket) else {
        rocket::error!("Failed to connect to the database");
        return Err(rocket);
    };

    let Err(e) = util::migrate(&db.0).await else {
        return Ok(rocket);
    };

    rocket::error!("Failed to run database migrations: {e}");
    Err(rocket)
}

#[must_use]
pub fn app() -> rocket::fairing::AdHoc {
    rocket::fairing::AdHoc::on_ignite("main", |rocket| async {
        let rocket = rocket
            .attach(Data::init())
            .attach(rocket::fairing::AdHoc::try_on_ignite(
                "run migrations",
                run_migrations,
            ));

        #[cfg(target_family = "unix")]
        let rocket = rocket.attach(rocket::fairing::AdHoc::on_liftoff("sd-notify", |_| {
            if let Err(err) = sd_notify::notify(true, &[sd_notify::NotifyState::Ready]) {
                rocket::error!("failed to notify systemd that this service is ready: {err}");
            }

            std::future::ready(()).boxed()
        }));

        rocket.mount("/", rocket::routes![health_check, landed])
    })
}

#[derive(rocket_db_pools::Database, Debug)]
#[database("data")]
struct Data(sqlx::Pool<sqlx::Postgres>);

#[rocket::get("/api/v1/<pr>")]
async fn landed(
    mut db: Connection<Data>,
    pr: i32,
) -> Result<rocket::serde::json::Json<LandedIn>, LandedError> {
    let landings = pr_tracker_store::Landing::for_pr(&mut db, pr.try_into()?).await?;

    let branches = landings
        .into_iter()
        .map(|branch| Branch::new(branch.name()))
        .collect();

    Ok(rocket::serde::json::Json(LandedIn { branches }))
}

#[rocket::get("/api/v1/healthcheck")]
#[allow(clippy::needless_pass_by_value)]
fn health_check(_db: Connection<Data>) {}

#[derive(Serialize, Deserialize, Debug, PartialEq, Eq)]
#[serde(crate = "rocket::serde")]
pub struct Branch(pub String);

impl Branch {
    pub fn new(s: impl AsRef<str>) -> Self {
        Self(s.as_ref().to_string())
    }
}

#[derive(Serialize, Deserialize, Debug, PartialEq, Eq)]
#[serde(crate = "rocket::serde")]
pub struct LandedIn {
    pub branches: Vec<Branch>,
}

enum LandedError {
    PrNumberNonPositive,
    ForPr(pr_tracker_store::ForPrError),
}

impl From<pr_tracker_store::PrNumberNonPositive> for LandedError {
    fn from(_value: pr_tracker_store::PrNumberNonPositive) -> Self {
        Self::PrNumberNonPositive
    }
}

impl From<pr_tracker_store::ForPrError> for LandedError {
    fn from(value: pr_tracker_store::ForPrError) -> Self {
        Self::ForPr(value)
    }
}

impl<'r, 'o: 'r> rocket::response::Responder<'r, 'o> for LandedError {
    fn respond_to(self, request: &'r rocket::Request<'_>) -> rocket::response::Result<'o> {
        match self {
            LandedError::PrNumberNonPositive => {
                let status = rocket::http::Status::from_code(400).unwrap();
                rocket::response::status::Custom(
                    status,
                    rocket::response::content::RawText("Non positive pull request number."),
                )
                .respond_to(request)
            }
            LandedError::ForPr(for_pr_error) => match for_pr_error {
                pr_tracker_store::ForPrError::Sqlx(_sqlx_error) => {
                    let status = rocket::http::Status::from_code(500).unwrap();
                    rocket::response::status::Custom(
                        status,
                        rocket::response::content::RawText("Error. Sorry."),
                    )
                    .respond_to(request)
                }
                pr_tracker_store::ForPrError::PrNotFound => rocket::response::status::NotFound(
                    rocket::response::content::RawText("Pull request not found."),
                )
                .respond_to(request),
            },
        }
    }
}
