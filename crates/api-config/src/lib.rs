#![allow(non_snake_case, clippy::struct_field_names)]

pub use environment::Environment;
use serde::Deserialize;
use serde_with::DisplayFromStr;
use serde_with::serde_as;
use tracing_subscriber::EnvFilter;

mod environment {
    include!(env!("api_config_snippet"));
}

#[serde_as]
#[derive(Deserialize, Debug)]
pub struct TracingFilter {
    #[serde_as(as = "DisplayFromStr")]
    pub env_filter: EnvFilter,
}

impl Default for TracingFilter {
    fn default() -> Self {
        Self {
            env_filter: EnvFilter::try_new("info").unwrap(),
        }
    }
}
