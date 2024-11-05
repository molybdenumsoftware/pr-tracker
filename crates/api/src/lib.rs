#![warn(clippy::pedantic)]
use std::time::Duration;

use poem::{endpoint::BoxEndpoint, http::StatusCode, web::Json, EndpointExt, Response};
use poem_openapi::{types::ToJSON, ApiResponse, OpenApi, OpenApiService};
use serde::{Deserialize, Serialize};
use sqlx::{
    pool::{PoolConnection, PoolOptions},
    Pool, Postgres,
};

use pr_tracker_store::{ForPrError, Landing, PrNumberNonPositiveError};

/// # Panics
/// See implementation.
pub async fn endpoint(db_url: &str) -> BoxEndpoint<'static> {
    let db_pool = PoolOptions::<Postgres>::new()
        .acquire_timeout(Duration::from_secs(5))
        .connect(db_url)
        .await
        .unwrap();

    let api_service = OpenApiService::new(
        Api,
        "Hello World", // TODO <<<
        "1.0",         // TODO <<<
    )
    .server(
        "http://localhost:3000/api", // TODO <<<
    );
    let ui = api_service.swagger_ui();

    util::migrate(&db_pool).await.unwrap();

    poem::Route::new()
        .nest("/api/v1", api_service)
        .nest("/", ui)
        //        .at("/api/v1/healthcheck", poem::get(health_check))
        //        .at("/api/v1/:pr", poem::get(landed))
        .with(poem::middleware::AddData::new(db_pool))
        .boxed()
}

pub struct DbConnection(PoolConnection<Postgres>);

impl<'a> poem::FromRequest<'a> for DbConnection {
    async fn from_request(
        req: &'a poem::Request,
        _body: &mut poem::RequestBody,
    ) -> poem::Result<Self> {
        let pool = req.extensions()
            .get::<Pool<Postgres>>()
            .expect("Could not find a db pool on `req.extensions`. Perhaps you forgot to register an `AddData` middleware that adds it?");
        let pool_connection = pool.acquire().await;
        let conn = pool_connection.map_err(poem::error::ServiceUnavailable)?;

        Ok(DbConnection(conn))
    }
}

struct Api;

#[OpenApi]
impl Api {
    #[oai(path = "/:pr", method = "get")]
    async fn landed(
        &self,
        poem::web::Path(pr): poem::web::Path<i32>,
        DbConnection(mut conn): DbConnection,
    ) -> poem::Result<poem_openapi::payload::Json<LandedIn>, LandedError> {
        let landings = Landing::for_pr(&mut conn, pr.try_into()?).await?;

        let branches = landings
            .into_iter()
            .map(|branch| Branch::new(branch.name()))
            .collect();

        Ok(poem_openapi::payload::Json(LandedIn { branches }))
    }

    #[oai(path = "/healthcheck", method = "get")]
    async fn health_check(&self, _db: DbConnection) {}
}

#[derive(Serialize, Deserialize, Debug, PartialEq, Eq, poem_openapi::NewType)]
pub struct Branch(pub String);

impl Branch {
    pub fn new(s: impl AsRef<str>) -> Self {
        Self(s.as_ref().to_string())
    }
}

#[derive(Serialize, Deserialize, Debug, PartialEq, Eq, poem_openapi::Object)]
pub struct LandedIn {
    pub branches: Vec<Branch>,
}

#[derive(Debug, thiserror::Error, ApiResponse)]
enum LandedError {
    #[error(transparent)]
    PrNumberNonPositive(#[from] PrNumberNonPositiveError),
    #[error(transparent)]
    Sqlx(sqlx::Error),
    #[error("Pull request not found.")]
    PrNotFound,
}

impl From<ForPrError> for LandedError {
    fn from(value: ForPrError) -> Self {
        match value {
            ForPrError::Sqlx(e) => Self::Sqlx(e),
            ForPrError::PrNotFound => Self::PrNotFound,
        }
    }
}

impl poem::error::ResponseError for LandedError {
    fn status(&self) -> StatusCode {
        match self {
            LandedError::PrNumberNonPositive(PrNumberNonPositiveError) => StatusCode::BAD_REQUEST,
            LandedError::Sqlx(_sqlx_error) => StatusCode::INTERNAL_SERVER_ERROR,
            LandedError::PrNotFound => StatusCode::NOT_FOUND,
        }
    }

    fn as_response(&self) -> Response
    where
        Self: std::error::Error + Send + Sync + 'static,
    {
        let body = match self {
            LandedError::PrNumberNonPositive(PrNumberNonPositiveError) => {
                "Non positive pull request number.".to_owned()
            }
            LandedError::Sqlx(_sqlx_error) => "Error. Sorry.".to_owned(),
            LandedError::PrNotFound => self.to_string(),
        };

        Response::builder().status(self.status()).body(body)
    }
}
