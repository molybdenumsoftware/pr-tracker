use db_context::LogDestination;
use poem::endpoint::BoxEndpoint;

#[derive(getset::Getters, getset::MutGetters)]
pub struct TestContext {
    // This value represents a running DB even if the field is not used.
    #[allow(dead_code)]
    #[getset(get = "pub", get_mut = "pub")]
    db: db_context::DatabaseContext,
    #[getset(get = "pub")]
    client: poem::test::TestClient<BoxEndpoint<'static>>,
}

impl TestContext {
    pub async fn with(test: impl AsyncFnOnce(TestContext)) {
        db_context::DatabaseContext::with(
            async |db_context| {
                let db_url = db_context.db_url();
                let endpoint = pr_tracker_api::endpoint(&db_url).await;

                let api_client = poem::test::TestClient::new(endpoint);

                let this = TestContext {
                    db: db_context,
                    client: api_client,
                };

                test(this).await
            },
            LogDestination::Inherit,
        )
        .await;
    }
}
