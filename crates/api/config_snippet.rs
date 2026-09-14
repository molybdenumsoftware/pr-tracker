// This file is generated

/// See documentation for each field.
#[derive(::std::fmt::Debug, ::confique::Config)]
pub struct Environment {
  /// [PostgreSQL connection URI](https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING-URIS).
  #[config(env = "PR_TRACKER_API_DATABASE_URL")]
  pub PR_TRACKER_API_DATABASE_URL: ::std::string::String,
  /// Port to listen on.
  #[config(env = "PR_TRACKER_API_PORT")]
  pub PR_TRACKER_API_PORT: ::core::primitive::u16,
  /// Optional.
  /// Expected to deserialize into an [`EnvFilter`](https://docs.rs/tracing-subscriber/latest/tracing_subscriber/filter/struct.EnvFilter.html).
  /// 
  #[config(env = "PR_TRACKER_TRACING_FILTER")]
  pub PR_TRACKER_TRACING_FILTER: Option<TracingFilter>,
}
