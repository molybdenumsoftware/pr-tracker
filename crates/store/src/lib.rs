#![warn(clippy::pedantic)]

use std::{collections::BTreeMap, num::NonZeroU32};

use futures::FutureExt;
use sqlx::{Connection, Postgres, Transaction};

pub use sqlx::PgConnection;

/// From 1 to [`i32::MAX`].
#[derive(Debug, PartialEq, Eq, PartialOrd, Ord, Clone, Copy)]
pub struct PrNumber(NonZeroU32);

#[derive(Debug, derive_more::From, PartialEq, Eq, PartialOrd, Ord, Clone, Copy)]
pub struct BranchId(i32);

#[derive(Debug, derive_more::From, PartialEq, Eq, Clone, Hash)]
#[from(forward)]
pub struct GitCommit(pub String);

#[derive(sqlx::FromRow, PartialEq, Eq, Debug, Clone)]
pub struct Pr {
    pub number: PrNumber,
    pub commit: Option<GitCommit>,
}

impl Ord for Pr {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        self.number.cmp(&other.number)
    }
}

impl PartialOrd for Pr {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        Some(self.cmp(other))
    }
}

impl Pr {
    /// Inserts this Pr into the database, or does nothing if it's already there.
    ///
    /// # Errors
    ///
    /// See error type for details.
    ///
    /// # Panics
    ///
    /// See [`sqlx::query!`].
    pub async fn upsert(self, connection: &mut PgConnection) -> sqlx::Result<()> {
        let pr_number: i32 = self.number.into();
        sqlx::query!(
            "
            INSERT INTO github_prs(number, commit) VALUES ($1, $2)
            ON CONFLICT (number) DO UPDATE SET commit=$2
            ",
            pr_number,
            self.commit.map(|c| c.0),
        )
        .execute(&mut *connection)
        .await?;

        Ok(())
    }

    /// Retrieves all [`Pr`]s.
    ///
    /// # Errors
    ///
    /// See error type for details.
    ///
    /// # Panics
    ///
    /// See [`sqlx::query!`].
    pub async fn all(connection: &mut PgConnection) -> Result<Vec<Pr>, sqlx::Error> {
        sqlx::query!("SELECT * from github_prs")
            .map(|pr| Self {
                number: pr.number.try_into().unwrap(),
                commit: pr.commit.map(Into::into),
            })
            .fetch_all(connection)
            .await
    }

    /// Retrieves [`Pr`] for commit.
    ///
    /// # Errors
    ///
    /// See error type for details.
    ///
    /// # Panics
    ///
    /// See [`sqlx::query!`].
    pub async fn for_commit(
        connection: &mut PgConnection,
        commit: impl Into<GitCommit>,
    ) -> Result<Option<Self>, sqlx::Error> {
        sqlx::query!(
            "SELECT * from github_prs where commit = $1",
            commit.into().0
        )
        .map(|pr| Self {
            number: pr.number.try_into().unwrap(),
            commit: pr.commit.map(Into::into),
        })
        .fetch_optional(connection)
        .await
    }
}

#[derive(Debug, PartialEq, Eq, PartialOrd, Ord, Clone)]
pub struct GithubPrQueryCursor(String);

impl GithubPrQueryCursor {
    #[must_use]
    pub fn new(cursor: String) -> Self {
        Self(cursor)
    }

    /// Fetch the singleton cursor from the db, or None if it is not present.
    ///
    /// # Errors
    ///
    /// See error type for details.
    pub async fn get(connection: &mut PgConnection) -> sqlx::Result<Option<GithubPrQueryCursor>> {
        let record = sqlx::query!("SELECT cursor FROM github_pr_query_cursor LIMIT 1")
            .fetch_optional(connection)
            .await?;
        let Some(record) = record else {
            return Ok(None);
        };

        Ok(Some(GithubPrQueryCursor(record.cursor)))
    }

    /// Create or update the singleton cursor in the db.
    ///
    /// # Errors
    ///
    /// See error type for details.
    pub async fn upsert(new_cursor: &Self, connection: &mut PgConnection) -> sqlx::Result<()> {
        async fn transaction(
            new_cursor: GithubPrQueryCursor,
            txn: &mut Transaction<'_, Postgres>,
        ) -> sqlx::Result<()> {
            let old_cursor = GithubPrQueryCursor::get(txn).await?;

            match old_cursor {
                Some(_) => {
                    // There is only 1 row in this table, an unfiltered UPDATE will update it.
                    sqlx::query!(
                        "UPDATE github_pr_query_cursor SET cursor = $1",
                        new_cursor.0,
                    )
                    .execute(&mut **txn)
                    .await?;
                }
                None => {
                    sqlx::query!(
                        "INSERT INTO github_pr_query_cursor (cursor) VALUES ($1)",
                        new_cursor.0,
                    )
                    .execute(&mut **txn)
                    .await?;
                }
            }

            Ok(())
        }

        connection
            .transaction(move |txn| transaction(new_cursor.clone(), txn).boxed())
            .await
    }

    #[must_use]
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

#[derive(Debug, thiserror::Error)]
#[error("pr number non positive")]
pub struct PrNumberNonPositiveError;

impl TryFrom<i32> for PrNumber {
    type Error = PrNumberNonPositiveError;

    fn try_from(value: i32) -> Result<Self, Self::Error> {
        let value = u32::try_from(value)
            .and_then(NonZeroU32::try_from)
            .map_err(|_| PrNumberNonPositiveError)?;
        Ok(Self(value))
    }
}

impl From<PrNumber> for i32 {
    fn from(value: PrNumber) -> Self {
        u32::from(value.0)
            .try_into()
            .expect("should not be larger than i32::MAX")
    }
}

#[derive(Debug, thiserror::Error)]
pub enum PrNumberFromI64Error {
    #[error("pull request number non-positive")]
    NonPositive,
    #[error("pull request number too large")]
    TooLarge,
}

impl TryFrom<i64> for PrNumber {
    type Error = PrNumberFromI64Error;

    fn try_from(value: i64) -> Result<Self, Self::Error> {
        const MAX: i64 = i32::MAX as i64;
        let value = match value {
            ..=0 => return Err(Self::Error::NonPositive),
            1..=MAX => value,
            _ => return Err(Self::Error::TooLarge),
        };

        let value = u32::try_from(value).unwrap();
        let value = NonZeroU32::try_from(value).unwrap();
        Ok(Self(value))
    }
}

#[derive(Debug, thiserror::Error)]
pub enum PrNumberFromUsizeError {
    #[error("pull request number is zero")]
    IsZero,
    #[error("pull request number too large")]
    TooLarge,
}

impl TryFrom<usize> for PrNumber {
    type Error = PrNumberFromUsizeError;

    fn try_from(value: usize) -> Result<Self, Self::Error> {
        const MAX: usize = i32::MAX as usize;
        let value = match value {
            0 => return Err(Self::Error::IsZero),
            1..=MAX => value,
            _ => return Err(Self::Error::TooLarge),
        };

        let value = u32::try_from(value).unwrap();
        let value = NonZeroU32::try_from(value).unwrap();
        Ok(Self(value))
    }
}

impl From<PrNumber> for NonZeroU32 {
    fn from(value: PrNumber) -> Self {
        value.0
    }
}

#[derive(sqlx::FromRow, PartialEq, Eq, Debug)]
pub struct Landing {
    pub github_pr: PrNumber,
    pub branch_id: BranchId,
}

#[derive(Debug, PartialEq, Eq, PartialOrd, Ord, derive_more::From, getset::CopyGetters)]
pub struct Branch {
    #[getset(get_copy = "pub")]
    id: BranchId,
    name: String,
}

impl Branch {
    /// Gets from or inserts into database.
    ///
    /// # Errors
    ///
    /// See error type for details.
    pub async fn get_or_insert(
        connection: &mut PgConnection,
        name: impl AsRef<str>,
    ) -> sqlx::Result<Self> {
        async fn transaction(
            name: String,
            txn: &mut Transaction<'_, Postgres>,
        ) -> sqlx::Result<Branch> {
            let branch = sqlx::query_as!(Branch, "SELECT * from branches WHERE name = $1", name)
                .fetch_optional(&mut **txn)
                .await?;
            if let Some(branch) = branch {
                Ok(branch)
            } else {
                sqlx::query_as!(
                    Branch,
                    "INSERT INTO branches (name) VALUES ($1) RETURNING *",
                    name
                )
                .fetch_one(&mut **txn)
                .await
            }
        }

        let s = name.as_ref().to_owned();
        connection
            .transaction(move |txn| transaction(s, txn).boxed())
            .await
    }

    /// Retrieve all from database.
    ///
    /// # Errors
    ///
    /// See error type for details.
    pub async fn all(connection: &mut PgConnection) -> sqlx::Result<BTreeMap<BranchId, Self>> {
        Ok(sqlx::query_as!(Branch, "SELECT * FROM branches")
            .fetch_all(connection)
            .await?
            .into_iter()
            .map(|branch| (branch.id, branch))
            .collect())
    }

    #[must_use]
    pub fn name(&self) -> &str {
        &self.name
    }
}

#[derive(Debug, thiserror::Error)]
pub enum ForPrError {
    #[error(transparent)]
    Sqlx(sqlx::Error),
    #[error("pr not found")]
    PrNotFound,
}

impl From<sqlx::Error> for ForPrError {
    fn from(value: sqlx::Error) -> Self {
        Self::Sqlx(value)
    }
}

impl Landing {
    /// Retrieves all [`Branch`]s this PR has landed in.
    ///
    /// # Errors
    ///
    /// See error type for details.
    ///
    /// # Panics
    ///
    /// See [`sqlx::query!`].
    pub async fn for_pr(
        connection: &mut PgConnection,
        pr_num: PrNumber,
    ) -> Result<Vec<Branch>, ForPrError> {
        async fn transaction(
            txn: &mut Transaction<'_, Postgres>,
            pr_num: PrNumber,
        ) -> Result<Vec<Branch>, ForPrError> {
            let pr_num: i32 = pr_num.into();

            let exists = sqlx::query!("SELECT 1 as pr from github_prs where number = $1", pr_num)
                .fetch_optional(&mut **txn)
                .await?
                .is_some();

            if !exists {
                return Err(ForPrError::PrNotFound);
            }

            let records = sqlx::query_as!(Branch,
                "SELECT branches.id, branches.name from landings, branches where landings.github_pr = $1 AND landings.branch_id = branches.id",
                pr_num,
            )
            .fetch_all(&mut **txn)
            .await?;

            let branches = records;

            Ok(branches)
        }

        let branches = connection
            .transaction(|txn| transaction(txn, pr_num).boxed())
            .await?;

        Ok(branches)
    }

    /// Retrieves all [`Landings`]s.
    ///
    /// # Errors
    ///
    /// See error type for details.
    ///
    /// # Panics
    ///
    /// See [`sqlx::query!`].
    pub async fn all(connection: &mut PgConnection) -> Result<Vec<Self>, sqlx::Error> {
        sqlx::query!("SELECT * from landings")
            .map(|landing| Self {
                github_pr: landing.github_pr.try_into().unwrap(),
                branch_id: BranchId(landing.branch_id),
            })
            .fetch_all(connection)
            .await
    }

    /// Upserts provided value into the database.
    ///
    /// # Errors
    ///
    /// See error type for details.
    pub async fn upsert(self, connection: &mut PgConnection) -> sqlx::Result<()> {
        async fn transaction(
            txn: &mut Transaction<'_, Postgres>,
            landing: Landing,
        ) -> sqlx::Result<()> {
            let pr_number: i32 = landing.github_pr.into();
            sqlx::query!(
                "INSERT INTO landings(github_pr, branch_id) VALUES ($1, $2) ON CONFLICT (github_pr, branch_id) DO NOTHING",
                pr_number,
                landing.branch_id.0,
            )
            .execute(&mut **txn)
            .await?;

            Ok(())
        }

        connection
            .transaction(|txn| transaction(txn, self).boxed())
            .await?;
        Ok(())
    }
}
