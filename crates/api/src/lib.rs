#![warn(clippy::pedantic)]
use std::time::Duration;

use poem::{endpoint::BoxEndpoint, EndpointExt};
use poem_openapi::{payload::PlainText, ApiResponse, OpenApi, OpenApiService};
use serde::{Deserialize, Serialize};
use sqlx::{
    pool::{PoolConnection, PoolOptions},
    Pool, Postgres,
};

use pr_tracker_store::{ForPrError, Landing, PrNumberNonPositiveError};

const DOCS_PATH: &str = "/api-docs";

#[poem::handler]
fn index() -> poem::web::Redirect {
    poem::web::Redirect::see_other(DOCS_PATH)
}

/// # Panics
/// See implementation.
pub async fn endpoint(db_url: &str) -> BoxEndpoint<'static> {
    const API_PREFIX: &str = "/api";

    let db_pool = PoolOptions::<Postgres>::new()
        .acquire_timeout(Duration::from_secs(5))
        .connect(db_url)
        .await
        .unwrap();

    let api_service = OpenApiService::new(Api, env!("CARGO_PKG_NAME"), env!("CARGO_PKG_VERSION"))
        .url_prefix(API_PREFIX);

    util::migrate(&db_pool).await.unwrap();

    poem::Route::new()
        .at("/", poem::get(index))
        .nest(DOCS_PATH, api_service.swagger_ui())
        .at("/openapi.json", api_service.spec_endpoint())
        .nest(API_PREFIX, api_service)
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

#[OpenApi(prefix_path = "/v1")]
impl Api {
    #[oai(path = "/:pr", method = "get")]
    async fn landed(
        &self,
        poem_openapi::param::Path(pr): poem_openapi::param::Path<i32>,
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
    #[allow(clippy::unused_async)]
    async fn health_check(&self, DbConnection(_conn): DbConnection) -> PlainText<&'static str> {
        PlainText("Here is your 200, but in the body")
    }
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

#[derive(Debug, ApiResponse)]
enum LandedError {
    #[oai(status = 400)]
    PrNumberNonPositive(PlainText<String>),

    #[oai(status = 500)]
    Sqlx(PlainText<String>),

    #[oai(status = 404)]
    PrNotFound(PlainText<String>),
}

impl From<PrNumberNonPositiveError> for LandedError {
    fn from(_: PrNumberNonPositiveError) -> Self {
        Self::PrNumberNonPositive(PlainText(String::from("Pull request number non-positive.")))
    }
}

impl From<ForPrError> for LandedError {
    fn from(value: ForPrError) -> Self {
        match value {
            ForPrError::Sqlx(_) => Self::Sqlx(poem_openapi::payload::PlainText(String::from(
                "Error. Sorry.",
            ))),
            ForPrError::PrNotFound => {
                Self::PrNotFound(PlainText(String::from("Pull request not found.")))
            }
        }
    }
}
