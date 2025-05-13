#![allow(non_snake_case, clippy::struct_field_names)]

pub use environment::Environment;
use serde::Deserialize;

mod environment {
    use confique::Config;

    /// See documentation for each field.
    #[derive(Debug, Config)]
    pub struct Environment {
        #[doc = include_str!("../../DATABASE_URL.md")]
        #[config(env = "PR_TRACKER_API_DATABASE_URL")]
        pub PR_TRACKER_API_DATABASE_URL: String,
        #[config(env = "PR_TRACKER_API_PORT")]
        #[doc = include_str!("../PORT.md")]
        pub PR_TRACKER_API_PORT: u16,
        #[config(env = "PR_TRACKER_SOMETHING")]
        #[doc = include_str!("../PORT.md")] //<<<
        pub PR_TRACKER_SOMETHING: EnvFilter,
    }
}

struct EnvFilter(tracing_subscriber::EnvFilter);

impl Deserialize for EnvFilter {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        todo!()
    }
}
