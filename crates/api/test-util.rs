use db_context::LogDestination;
use futures::{future::LocalBoxFuture, FutureExt};
use poem::endpoint::BoxEndpoint;

pub struct TestContext<'a> {
    // sorry, Rust — definitely in use
    // #[allow(dead_code)] // TODO okay now?
    pub db: &'a mut db_context::DatabaseContext,
    // sorry, Rust — definitely in use
    // #[allow(dead_code)] // TODO okay now?
    pub client: poem::test::TestClient<BoxEndpoint<'a>>,
}

impl TestContext<'_> {
    pub async fn with<F>(
        test: F,
        // <<< test: impl for<'a> FnOnce(&'a mut TestContext<'a, impl poem::Endpoint>) -> LocalBoxFuture<()>
        // <<< + 'static,
    ) where
        F: FnOnce(TestContext<'_>) -> LocalBoxFuture<()> + 'static,
    {
        db_context::DatabaseContext::with(
            |db_context| {
                async {
                    let db_url = db_context.db_url();
                    let app = pr_tracker_api::app(&db_url).await.unwrap();
                    // <<< let rocket = rocket::custom(
                    // <<<     rocket::figment::Figment::from(rocket::Config::default())
                    // <<<         .merge(("databases.data.url", db_context.db_url()))
                    // <<<         .merge(("log_level", rocket::config::LogLevel::Debug)),
                    // <<< )
                    // <<< .attach(app);
                    // <<<
                    // <<< let api_client = rocket::local::asynchronous::Client::tracked(rocket)
                    // <<<     .await
                    // <<<     .unwrap();

                    let api_client = poem::test::TestClient::new(app);

                    let test_context = TestContext {
                        db: db_context,
                        client: api_client,
                    };

                    test(test_context).await
                }
                .boxed_local()
            },
            LogDestination::Inherit,
        )
        .await;
    }
}
