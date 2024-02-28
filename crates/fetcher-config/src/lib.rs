#![allow(non_snake_case, clippy::struct_field_names)]

pub use environment::Environment;

mod environment {
    use camino::Utf8PathBuf;
    use confique::Config;

    #[derive(Debug, Config)]
    pub struct Environment {
        /// A Postgres connection URL.
        #[config(env = "PR_TRACKER_FETCHER_DATABASE_URL")]
        pub PR_TRACKER_FETCHER_DATABASE_URL: String,
        #[config(env = "PR_TRACKER_FETCHER_GITHUB_TOKEN")]
        #[doc = include_str!("../GITHUB_TOKEN.md")]
        pub PR_TRACKER_FETCHER_GITHUB_TOKEN: String,
        #[config(env = "PR_TRACKER_FETCHER_GITHUB_REPO_OWNER")]
        #[doc = include_str!("../GITHUB_REPO_OWNER.md")]
        pub PR_TRACKER_FETCHER_GITHUB_REPO_OWNER: String,
        #[config(env = "PR_TRACKER_FETCHER_GITHUB_REPO_NAME")]
        #[doc = include_str!("../GITHUB_REPO_NAME.md")]
        pub PR_TRACKER_FETCHER_GITHUB_REPO_NAME: String,
        /// A directory for the fetcher to cache data (such as clones of repositories).
        #[config(env = "PR_TRACKER_FETCHER_CACHE_DIR")]
        pub PR_TRACKER_FETCHER_CACHE_DIR: Utf8PathBuf,
        #[config(env = "PR_TRACKER_FETCHER_BRANCH_PATTERNS")]
        #[doc = include_str!("../BRANCH_PATTERNS.md")]
        pub PR_TRACKER_FETCHER_BRANCH_PATTERNS: String,
    }
}
