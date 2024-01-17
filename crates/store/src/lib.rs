#![warn(clippy::pedantic)]

use std::num::NonZeroU16;

use futures::FutureExt;
use sqlx::Connection;

pub use sqlx::PgConnection;

#[derive(Debug, PartialEq, Eq, PartialOrd, Ord, Clone, Copy)]
pub struct PrNumber(NonZeroU16);

#[derive(Debug, derive_more::From, PartialEq, Eq, PartialOrd, Ord, Clone, Copy)]
pub struct BranchId(i32);

#[derive(Debug, derive_more::From, PartialEq, Eq, Clone)]
#[from(forward)]
pub struct GitCommit(pub String);

#[derive(sqlx::FromRow, PartialEq, Eq, Debug, Clone)]
pub struct Pr {
    pub number: PrNumber,
    pub commit: Option<GitCommit>,
}

impl Pr {
    /// Inserts provided value into the database.
    ///
    /// # Errors
    ///
    /// See error type for details.
    ///
    /// # Panics
    ///
    /// See [`sqlx::query!`].
    pub async fn insert(self, connection: &mut sqlx::PgConnection) -> sqlx::Result<()> {
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

    /// Bulk insert PRs
    ///
    /// # Errors
    ///
    /// See error type for details.
    pub async fn bulk_insert(
        connection: &mut sqlx::PgConnection,
        prs: Vec<Self>,
    ) -> sqlx::Result<()> {
        // TODO: look into doing a real bulk insert with sqlx
        for pr in prs {
            pr.insert(connection).await?;
        }
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
    pub async fn all(connection: &mut sqlx::PgConnection) -> Result<Vec<Pr>, sqlx::Error> {
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
        connection: &mut sqlx::PgConnection,
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

impl From<NonZeroU16> for PrNumber {
    fn from(value: NonZeroU16) -> Self {
        Self(value)
    }
}

#[derive(Debug)]
pub struct PrNumberNonPositive;

impl TryFrom<i32> for PrNumber {
    type Error = PrNumberNonPositive;

    fn try_from(value: i32) -> Result<Self, Self::Error> {
        let value = u16::try_from(value)
            .and_then(NonZeroU16::try_from)
            .map_err(|_| PrNumberNonPositive)?;
        Ok(Self(value))
    }
}

impl From<PrNumber> for i32 {
    fn from(value: PrNumber) -> Self {
        u16::from(value.0).into()
    }
}

#[derive(sqlx::FromRow, PartialEq, Eq, PartialOrd, Ord, Debug)]
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
    /// Gets or inserts.
    ///
    /// # Errors
    ///
    /// See error type for details.
    pub async fn get_or_insert(
        connection: &mut sqlx::PgConnection,
        name: impl AsRef<str>,
    ) -> sqlx::Result<Self> {
        async fn transaction(
            name: String,
            txn: &mut sqlx::Transaction<'_, sqlx::Postgres>,
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

    /// .
    ///
    /// # Errors
    ///
    /// This function will return an error if .
    pub async fn all(
        connection: &mut sqlx::PgConnection,
    ) -> sqlx::Result<std::collections::BTreeMap<BranchId, Self>> {
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

pub enum ForPrError {
    Sqlx(sqlx::Error),
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
        connection: &mut sqlx::PgConnection,
        pr_num: PrNumber,
    ) -> Result<Vec<Branch>, ForPrError> {
        async fn transaction(
            txn: &mut sqlx::Transaction<'_, sqlx::Postgres>,
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
    pub async fn all(connection: &mut sqlx::PgConnection) -> Result<Vec<Self>, sqlx::Error> {
        sqlx::query!("SELECT * from landings")
            .map(|landing| Self {
                github_pr: landing.github_pr.try_into().unwrap(),
                branch_id: BranchId(landing.branch_id),
            })
            .fetch_all(connection)
            .await
    }

    /// Inserts provided value into the database.
    ///
    /// # Errors
    ///
    /// See error type for details.
    pub async fn insert(self, connection: &mut sqlx::PgConnection) -> sqlx::Result<()> {
        async fn transaction(
            txn: &mut sqlx::Transaction<'_, sqlx::Postgres>,
            landing: Landing,
        ) -> sqlx::Result<()> {
            let pr_number: i32 = landing.github_pr.into();
            sqlx::query!(
                "INSERT INTO landings(github_pr, branch_id) VALUES ($1, $2)",
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
