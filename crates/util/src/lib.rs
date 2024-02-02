use std::ops::Deref;

use sqlx::migrate::{Migrate, MigrateError};

pub async fn migrate<'a, A>(migrator: A) -> Result<(), MigrateError>
where
    A: sqlx::Acquire<'a>,
    <A::Connection as Deref>::Target: Migrate,
{
    sqlx::migrate!("./migrations").run(migrator).await
}
