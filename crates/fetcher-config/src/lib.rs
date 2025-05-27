#![allow(non_snake_case, clippy::struct_field_names)]

pub use environment::Environment;

mod environment {
    include!(env!("fetcher_config_snippet"));
}
