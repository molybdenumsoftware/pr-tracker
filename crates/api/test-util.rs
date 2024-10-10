use db_context::LogDestination;
use futures::future::LocalBoxFuture;

pub struct TestContext<'a, E> {
    // sorry, Rust — definitely in use
    // #[allow(dead_code)] // TODO okay now?
    pub db: &'a mut db_context::DatabaseContext,
    // sorry, Rust — definitely in use
    // #[allow(dead_code)] // TODO okay now?
    pub client: poem::test::TestClient<E>,
}

impl<E, F> TestContext<'_, E>
where
    F: for<'a> FnOnce(&'a mut TestContext<'a, E>) -> LocalBoxFuture<()>,
    E: poem::Endpoint,
{
    pub async fn with(
        test: T,
        // <<< test: impl for<'a> FnOnce(&'a mut TestContext<'a, impl poem::Endpoint>) -> LocalBoxFuture<()>
        // <<< + 'static,
    ) {
        db_context::DatabaseContext::with(
            |db_context| {
                async {
                    let app = pr_tracker_api::app(&db_context.db_url()).await.unwrap();
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

                    let mut this = TestContext {
                        db: db_context,
                        client: api_client,
                    };

                    test(&mut this).await
                }
                .boxed_local()
            },
            LogDestination::Inherit,
        )
        .await;
    }
}
