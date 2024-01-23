#![warn(clippy::pedantic)]
// required because rocket::routes, remove if clippy permits.
#![allow(clippy::no_effect_underscore_binding)]

use pr_tracker_store::{ForPrError, Landing, PrNumberNonPositive};
use rocket::{
    futures::FutureExt,
    http::Status,
    response::{self, status},
    serde::{json::Json, Deserialize, Serialize},
    Request, Rocket,
};
use rocket_db_pools::{Connection, Database};

async fn run_migrations(rocket: Rocket<rocket::Build>) -> rocket::fairing::Result {
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
async fn landed(mut db: Connection<Data>, pr: i32) -> Result<Json<LandedIn>, LandedError> {
    let landings = Landing::for_pr(&mut db, pr.try_into()?).await?;

    let branches = landings
        .into_iter()
        .map(|branch| Branch::new(branch.name()))
        .collect();

    Ok(Json(LandedIn { branches }))
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
    ForPr(ForPrError),
}

impl From<PrNumberNonPositive> for LandedError {
    fn from(_value: PrNumberNonPositive) -> Self {
        Self::PrNumberNonPositive
    }
}

impl From<ForPrError> for LandedError {
    fn from(value: ForPrError) -> Self {
        Self::ForPr(value)
    }
}

impl<'r, 'o: 'r> response::Responder<'r, 'o> for LandedError {
    fn respond_to(self, request: &'r Request<'_>) -> response::Result<'o> {
        match self {
            LandedError::PrNumberNonPositive => {
                let status = Status::from_code(400).unwrap();
                status::Custom(
                    status,
                    response::content::RawText("Non positive pull request number."),
                )
                .respond_to(request)
            }
            LandedError::ForPr(ForPrError::Sqlx(_sqlx_error)) => {
                let status = Status::from_code(500).unwrap();
                status::Custom(status, response::content::RawText("Error. Sorry."))
                    .respond_to(request)
            }
            LandedError::ForPr(ForPrError::PrNotFound) => {
                status::NotFound(response::content::RawText("Pull request not found."))
                    .respond_to(request)
            }
        }
    }
}
