create table github_prs (
    number int PRIMARY KEY,
    commit varchar(40)
);

create table branches (
    id serial PRIMARY KEY,
    name varchar(255) not null unique
);

create table landings (
    github_pr int not null references github_prs(number),
    branch_id int not null references branches(id)
);

create table github_pr_query_cursor (
  cursor varchar(255) not null
);
