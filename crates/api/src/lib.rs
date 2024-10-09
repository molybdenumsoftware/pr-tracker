#![warn(clippy::pedantic)]
use poem::{http::StatusCode, web::Json, EndpointExt, Response};
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
) -> poem::Result<LandedIn> {
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
    fn status(&self) -> StatusCode {
        match self {
            LandedError::PrNumberNonPositive(PrNumberNonPositiveError) => StatusCode::BAD_REQUEST,
            LandedError::ForPr(ForPrError::Sqlx(_sqlx_error)) => StatusCode::INTERNAL_SERVER_ERROR,
            LandedError::ForPr(ForPrError::PrNotFound) => StatusCode::NOT_FOUND,
        }
    }

    fn as_response(&self) -> Response
    where
        Self: std::error::Error + Send + Sync + 'static,
    {
        let body = match self {
            LandedError::PrNumberNonPositive(PrNumberNonPositiveError) => {
                "Non positive pull request number."
            }
            LandedError::ForPr(ForPrError::Sqlx(_sqlx_error)) => "Error. Sorry.",
            LandedError::ForPr(ForPrError::PrNotFound) => "Pull request not found.",
        };

        Response::builder().status(self.status()).body(body)
    }
}
