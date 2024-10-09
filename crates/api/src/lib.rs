#![warn(clippy::pedantic)]
use poem::EndpointExt;
use serde::{Deserialize, Serialize};
use sqlx::{migrate::MigrateError, Connection, PgConnection, PgPool};

use pr_tracker_store::{ForPrError, Landing, PrNumberNonPositiveError};

#[must_use]
pub async fn app() -> Result<impl poem::IntoEndpoint, MigrateError> {
    let url = ">>> TODO <<<";
    let db_pool = PgPool::connect(&url).await.unwrap(); // TODO handle error (or not)

    util::migrate(&db_pool).await?;

    Ok(poem::Route::new()
        .at("/api/v1/healthcheck", poem::get(health_check))
        .at("/api/v1/:pr", poem::get(landed))
        .with(poem::middleware::AddData::new(db_pool)))

    //<<< rocket::fairing::AdHoc::on_ignite("main", |rocket| async {
    //<<<     let rocket = rocket
    //<<<         .attach(Data::init())
    //<<<         .attach(rocket::fairing::AdHoc::try_on_ignite(
    //<<<             "run migrations",
    //<<<             run_migrations,
    //<<<         ));
    //<<<
    //<<<     #[cfg(target_family = "unix")]
    //<<<     let rocket = rocket.attach(rocket::fairing::AdHoc::on_liftoff("sd-notify", |_| {
    //<<<         if let Err(err) = sd_notify::notify(true, &[sd_notify::NotifyState::Ready]) {
    //<<<             rocket::error!("failed to notify systemd that this service is ready: {err}");
    //<<<         }
    //<<<
    //<<<         std::future::ready(()).boxed()
    //<<<     }));
    //<<< })
}

#[poem::handler]
async fn landed(
    poem::web::Data(db_pool): poem::web::Data<&PgPool>,
    pr: i32,
) -> Result<LandedIn, LandedError> {
    let mut conn = db_pool.acquire().await.unwrap();
    let landings = Landing::for_pr(&mut conn, pr.try_into()?).await?;

    let branches = landings
        .into_iter()
        .map(|branch| Branch::new(branch.name()))
        .collect();

    Ok(LandedIn { branches })
}

#[poem::handler]
fn health_check() {}

#[derive(Serialize, Deserialize, Debug, PartialEq, Eq)]
pub struct Branch(pub String);

impl Branch {
    pub fn new(s: impl AsRef<str>) -> Self {
        Self(s.as_ref().to_string())
    }
}

#[derive(Serialize, Deserialize, Debug, PartialEq, Eq)]
pub struct LandedIn {
    pub branches: Vec<Branch>,
}

#[derive(Debug, thiserror::Error)]
enum LandedError {
    #[error(transparent)]
    PrNumberNonPositive(PrNumberNonPositiveError),
    #[error(transparent)]
    ForPr(ForPrError),
}

impl From<PrNumberNonPositiveError> for LandedError {
    fn from(value: PrNumberNonPositiveError) -> Self {
        Self::PrNumberNonPositive(value)
    }
}

impl From<ForPrError> for LandedError {
    fn from(value: ForPrError) -> Self {
        Self::ForPr(value)
    }
}

impl poem::error::ResponseError for LandedError {
    fn respond_to(self, request: &'r Request<'_>) -> response::Result<'o> {
        match self {
            LandedError::PrNumberNonPositive(PrNumberNonPositiveError) => {
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

    fn status(&self) -> poem::http::StatusCode {
        match self {
            LandedError::PrNumberNonPositive(_) => todo!(),
            LandedError::ForPr(_) => todo!(),
        }
    }
}
