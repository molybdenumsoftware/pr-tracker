use rocket::futures::FutureExt;

pub struct TestContext<'a> {
    // sorry, Rust — definitely in use
    #[allow(dead_code)]
    pub db: &'a mut db_context::DatabaseContext,
    // sorry, Rust — definitely in use
    #[allow(dead_code)]
    pub client: rocket::local::asynchronous::Client,
}

impl TestContext<'_> {
    pub async fn with(
        test: impl for<'a> FnOnce(&'a mut TestContext<'a>) -> rocket::futures::future::LocalBoxFuture<()>
            + 'static,
    ) {
        db_context::DatabaseContext::with(|db_context| {
            async {
                let rocket = rocket::custom(
                    rocket::figment::Figment::from(rocket::Config::default())
                        .merge(("databases.data.url", db_context.db_url()))
                        .merge(("log_level", rocket::config::LogLevel::Debug)),
                )
                .attach(pr_tracker_api::app());

                let api_client = rocket::local::asynchronous::Client::tracked(rocket)
                    .await
                    .unwrap();

                let mut this = TestContext {
                    db: db_context,
                    client: api_client,
                };

                test(&mut this).await
            }
            .boxed_local()
        })
        .await;
    }
}
