#![warn(clippy::pedantic)]
use std::time::Duration;

use poem::middleware::RequestId;
use poem::{
    EndpointExt, FromRequest, Request, RequestBody, Route, endpoint::BoxEndpoint, middleware,
    web::Redirect,
};
use poem_openapi::{ApiResponse, OpenApi, OpenApiService, param, payload};
use serde::{Deserialize, Serialize};
use sqlx::{
    Pool, Postgres,
    pool::{PoolConnection, PoolOptions},
};

use pr_tracker_store::{ForPrError, Landing, PrNumberNonPositiveError};

const DOCS_PATH: &str = "/api-docs";

#[poem::handler]
fn index() -> Redirect {
    Redirect::see_other(DOCS_PATH)
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

    Route::new()
        .at("/", poem::get(index))
        .nest(DOCS_PATH, api_service.swagger_ui())
        .at("/openapi.json", api_service.spec_endpoint())
        .nest(API_PREFIX, api_service)
        .with(middleware::AddData::new(db_pool))
        .with(middleware::Tracing)
        .with(RequestId::default())
        .boxed()
}

pub struct DbConnection(PoolConnection<Postgres>);

impl<'a> FromRequest<'a> for DbConnection {
    async fn from_request(req: &'a Request, _body: &mut RequestBody) -> poem::Result<Self> {
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
    #[allow(clippy::unused_async)]
    #[oai(path = "/v1/:_", method = "get")]
    async fn v1(&self) -> V1Response {
        V1Response::NotSupported(payload::PlainText("API v1 not supported"))
    }

    #[oai(path = "/v2/landings/:pr", method = "get")]
    async fn landed(
        &self,
        param::Path(pr): param::Path<i32>,
        DbConnection(mut conn): DbConnection,
    ) -> poem::Result<payload::Json<LandedIn>, NoLandingsResponse> {
        let landings = Landing::for_pr(&mut conn, pr.try_into()?).await?;

        let branches = landings
            .into_iter()
            .map(|branch| Branch::new(branch.name()))
            .collect();

        Ok(payload::Json(LandedIn { branches }))
    }

    #[oai(path = "/v2/healthcheck", method = "get")]
    #[allow(clippy::unused_async)]
    async fn health_check(
        &self,
        DbConnection(_conn): DbConnection,
    ) -> payload::PlainText<&'static str> {
        payload::PlainText("Here is your 200, but in the body")
    }
}

#[derive(ApiResponse)]
enum V1Response {
    #[oai(status = 404)]
    NotSupported(payload::PlainText<&'static str>),
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
enum NoLandingsResponse {
    #[oai(status = 400)]
    PrNumberNonPositive(payload::PlainText<String>),

    #[oai(status = 500)]
    Sqlx(payload::PlainText<String>),

    #[oai(status = 204)]
    PrNotFound(payload::PlainText<String>),
}

impl From<PrNumberNonPositiveError> for NoLandingsResponse {
    fn from(_: PrNumberNonPositiveError) -> Self {
        Self::PrNumberNonPositive(payload::PlainText(String::from(
            "Pull request number non-positive.",
        )))
    }
}

impl From<ForPrError> for NoLandingsResponse {
    fn from(value: ForPrError) -> Self {
        match value {
            ForPrError::Sqlx(_) => Self::Sqlx(payload::PlainText(String::from("Error. Sorry."))),
            ForPrError::PrNotFound => {
                Self::PrNotFound(payload::PlainText(String::from("Pull request not found.")))
            }
        }
    }
}
