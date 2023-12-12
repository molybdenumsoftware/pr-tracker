use rocket::futures::FutureExt;

trait Rocketable {
    fn rocket(&self) -> rocket::Rocket<rocket::Build>;
}

impl Rocketable for util::DatabaseContext {
    fn rocket(&self) -> rocket::Rocket<rocket::Build> {
        rocket::custom(
            rocket::figment::Figment::from(rocket::Config::default())
                .merge(("databases.data.url", self.db_url()))
                .merge(("log_level", rocket::config::LogLevel::Debug)),
        )
        .attach(pr_tracker_api::app())
    }
}

#[tokio::test]
async fn pr_not_found() {
    util::DatabaseContext::with(|ctx: &util::DatabaseContext| {
        async {
            let client = rocket::local::asynchronous::Client::tracked(ctx.rocket())
                .await
                .unwrap();
            let response = client.get("/landed/github/2134").dispatch().await;
            assert_eq!(response.status(), rocket::http::Status::NotFound);
            assert_eq!(
                response.into_string().await,
                Some("Pull request not found.".into())
            );
        }
        .boxed()
    })
    .await;
}

#[tokio::test]
async fn pr_not_landed() {
    util::DatabaseContext::with(|ctx| {
        async {
            let mut connection = ctx.connection().await.unwrap();

            pr_tracker_store::Pr {
                number: 123.try_into().unwrap(),
                commit: Some("deadbeef".into()),
            }
            .insert(&mut connection)
            .await
            .unwrap();

            let client = rocket::local::asynchronous::Client::tracked(ctx.rocket())
                .await
                .unwrap();

            let response = client.get("/landed/github/123").dispatch().await;
            assert_eq!(response.status(), rocket::http::Status::Ok);

            assert_eq!(
                response.into_json::<pr_tracker_api::LandedIn>().await.unwrap(),
                pr_tracker_api::LandedIn { branches: vec![] }
            );
        }
        .boxed()
    })
    .await;
}

#[tokio::test]
async fn pr_landed() {
    util::DatabaseContext::with(|ctx| {
        async {
            let connection = &mut ctx.connection().await.unwrap();

            let branch = pr_tracker_store::Branch::get_or_insert(connection, "nixos-unstable")
                .await
                .unwrap();

            let github_pr = pr_tracker_store::Pr {
                number: 2134.into(),
                commit: Some("deadbeef".into()),
            };
            github_pr.clone().insert(connection).await.unwrap();

            let landing = pr_tracker_store::Landing {
                github_pr: github_pr.number,
                branch_id: branch.id(),
            };

            landing.insert(connection).await.unwrap();

            let client = rocket::local::asynchronous::Client::tracked(ctx.rocket())
                .await
                .unwrap();

            let response = client.get("/landed/github/2134").dispatch().await;
            assert_eq!(response.status(), rocket::http::Status::Ok);

            assert_eq!(
                response.into_json::<pr_tracker_api::LandedIn>().await.unwrap(),
                pr_tracker_api::LandedIn {
                    branches: vec![pr_tracker_api::Branch("nixos-unstable".to_owned())]
                }
            );
        }
        .boxed()
    })
    .await;
}
