// This file is generated

/// See documentation for each field.
#[derive(::std::fmt::Debug, ::confique::Config)]
#[allow(clippy::doc_markdown)]
pub struct Environment {
  /// JSON array of strings representing branch patterns to track.
  /// 
  /// - `?` matches a single occurrence of any character.
  /// - `*` matches zero or more occurrences of any character.
  /// 
  /// No escape characters.
  /// 
  #[config(env = "PR_TRACKER_FETCHER_BRANCH_PATTERNS")]
  pub PR_TRACKER_FETCHER_BRANCH_PATTERNS: ::std::string::String,
  /// Cache directory (for repository clone).
  #[config(env = "PR_TRACKER_FETCHER_CACHE_DIR")]
  pub PR_TRACKER_FETCHER_CACHE_DIR: ::camino::Utf8PathBuf,
  /// PostgreSQL connection URI
  #[config(env = "PR_TRACKER_FETCHER_DATABASE_URL")]
  pub PR_TRACKER_FETCHER_DATABASE_URL: ::std::string::String,
  /// GitHub repository name.
  #[config(env = "PR_TRACKER_FETCHER_GITHUB_REPO_NAME")]
  pub PR_TRACKER_FETCHER_GITHUB_REPO_NAME: ::std::string::String,
  /// GitHub repository owner.
  #[config(env = "PR_TRACKER_FETCHER_GITHUB_REPO_OWNER")]
  pub PR_TRACKER_FETCHER_GITHUB_REPO_OWNER: ::std::string::String,
  /// GitHub API token with read access to the repository's pull requests.
  #[config(env = "PR_TRACKER_FETCHER_GITHUB_TOKEN")]
  pub PR_TRACKER_FETCHER_GITHUB_TOKEN: ::std::string::String,
}
