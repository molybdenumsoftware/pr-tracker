ALTER TABLE landings
ADD CONSTRAINT unique_landings
UNIQUE (github_pr, branch_id);
