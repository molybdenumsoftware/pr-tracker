#![allow(non_snake_case, clippy::struct_field_names)]

pub use environment::Environment;

mod environment {
    use confique::Config;
    use serde::Deserialize;
    use serde_with::DisplayFromStr;
    use serde_with::serde_as;

    /// See documentation for each field.
    #[derive(Debug, Config)]
    pub struct Environment {
        #[doc = include_str!("../../DATABASE_URL.md")]
        #[config(env = "PR_TRACKER_API_DATABASE_URL")]
        pub PR_TRACKER_API_DATABASE_URL: String,
        #[config(env = "PR_TRACKER_API_PORT")]
        #[doc = include_str!("../PORT.md")]
        pub PR_TRACKER_API_PORT: u16,
        #[config(env = "PR_TRACKER_TRACING_FILTER")]
        #[doc = include_str!("../PORT.md")] //<<<
        pub PR_TRACKER_TRACING_FILTER: EnvFilter,
    }

    #[serde_as]
    #[derive(Deserialize, Debug)]
    pub struct EnvFilter(#[serde_as(as = "DisplayFromStr")] pub tracing_subscriber::EnvFilter);
}
