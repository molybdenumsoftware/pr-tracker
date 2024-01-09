use std::path::Path;

fn main() {
    create_graphql_schema_symlink()
}

fn create_graphql_schema_symlink() {
    let symlink_target = Path::new(env!("GITHUB_GRAPHQL_SCHEMA"));

    let symlink_name = Path::new(concat!(
        env!("CARGO_MANIFEST_DIR"),
        "/src/graphql/schema.graphql"
    ));

    match std::fs::read_link(symlink_name) {
        Ok(existing_target) => {
            if existing_target == symlink_target {
                return;
            }
            std::fs::remove_file(symlink_name).unwrap();
        }
        Err(e) => {
            assert_eq!(e.kind(), std::io::ErrorKind::NotFound);
        }
    }

    std::os::unix::fs::symlink(symlink_target, symlink_name).unwrap();
}
