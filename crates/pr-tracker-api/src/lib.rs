#![warn(clippy::pedantic)]
// required because rocket::routes, remove if clippy permits.
#![allow(clippy::no_effect_underscore_binding)]

use rocket::serde::{Deserialize, Serialize};
use rocket_db_pools::{Connection, Database};

#[must_use]
pub fn app() -> rocket::fairing::AdHoc {
    rocket::fairing::AdHoc::on_ignite("main", |rocket| async {
        rocket
            .attach(Data::init())
            .mount("/", rocket::routes![landed])
    })
}

#[derive(rocket_db_pools::Database, Debug)]
#[database("data")]
struct Data(sqlx::Pool<sqlx::Postgres>);

#[rocket::get("/landed/github/<pr>")]
async fn landed(
    mut db: Connection<Data>,
    pr: u32,
) -> Result<rocket::serde::json::Json<LandedIn>, LandedError> {
    let landings = pr_tracker_store::Landing::for_pr(&mut db, pr.try_into()?).await?;

    let branches = landings
        .into_iter()
        .map(|branch| Branch::new(branch.name()))
        .collect();

    Ok(rocket::serde::json::Json(LandedIn { branches }))
}

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
    PrNumberTooLarge,
    ForPr(pr_tracker_store::ForPrError),
}

impl From<pr_tracker_store::PrNumberTooLarge> for LandedError {
    fn from(_value: pr_tracker_store::PrNumberTooLarge) -> Self {
        Self::PrNumberTooLarge
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
            LandedError::PrNumberTooLarge => rocket::response::status::BadRequest(
                rocket::response::content::RawText("Pull request number too large."),
            )
            .respond_to(request),
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
