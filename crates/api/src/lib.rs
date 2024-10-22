#![warn(clippy::pedantic)]
use poem::{
    endpoint::BoxEndpoint,
    http::StatusCode,
    listener::{Listener, TcpAcceptor, TcpListener},
    web::Json,
    EndpointExt, Response,
};
use serde::{Deserialize, Serialize};
use sqlx::{migrate::MigrateError, pool::PoolConnection, PgPool, Postgres};

use pr_tracker_store::{ForPrError, Landing, PrNumberNonPositiveError};

#[must_use]
pub async fn app<'a>(
    port: u16,
    db_url: &str,
) -> Result<(TcpAcceptor, BoxEndpoint<'a>), MigrateError> // TODO waaat:
{
    let acceptor = TcpListener::bind(format!("0.0.0.0:{port}"))
        .into_acceptor()
        .await
        .unwrap();

    sd_notify::notify(true, &[sd_notify::NotifyState::Ready]).unwrap(); //<<< TODO: give a nicer error message ("failed to notify systemd that this service is ready: {err}");

    let endpoint = endpoint(db_url).await?;
    Ok((acceptor, endpoint))
}

pub async fn endpoint<'a>(db_url: &str) -> Result<BoxEndpoint<'a>, MigrateError> {
    let db_pool = PgPool::connect(db_url).await.unwrap(); // TODO handle error (or not)
    util::migrate(&db_pool).await?;

    Ok(poem::Route::new()
        .at("/api/v1/healthcheck", poem::get(health_check))
        .at("/api/v1/:pr", poem::get(landed))
        .with(poem::middleware::AddData::new(db_pool))
        .boxed())
}

struct DbConnection(PoolConnection<Postgres>);
// <<< poem::web::Data(db_pool): poem::web::Data<&PgPool>,
// <<< let mut conn = db_pool.acquire().await.unwrap(); // TODO: don't panic

#[poem::handler]
async fn landed(
    poem::web::Path(pr): poem::web::Path<i32>,
    DbConnection(mut conn): DbConnection,
) -> poem::Result<poem::web::Json<LandedIn>, LandedError> {
    let landings = Landing::for_pr(&mut conn, pr.try_into()?).await?;

    let branches = landings
        .into_iter()
        .map(|branch| Branch::new(branch.name()))
        .collect();

    Ok(Json(LandedIn { branches }))
}

#[poem::handler]
async fn health_check(poem::web::Data(db_pool): poem::web::Data<&PgPool>) -> StatusCode {
    if db_pool.acquire().await.is_err() {
        StatusCode::SERVICE_UNAVAILABLE
    } else {
        StatusCode::OK
    }
}

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
