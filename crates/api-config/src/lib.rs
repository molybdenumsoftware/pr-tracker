#![allow(non_snake_case, clippy::struct_field_names)]

pub use environment::Environment;

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
    }
}
