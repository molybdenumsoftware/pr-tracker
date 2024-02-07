# pr-tracker

> For a certain GitHub pull request, if it is merged, which branches did it "land" in?

To be clear, a pull request had landed in a branch when its merge commit is in that branch.

As of 2024-02-02 GitHub does not provide an API for directly asking this question.
This project does.

In order to provide an API that answers this question the following are obtained:

1. All pull requests and their merge commits (via GitHub's GraphQL API).
2. A clone of the repository.

From these, all landings are deduced and stored in a database.

Two programs are provided:

1. pr-tracker-fetcher: obtains data, determines landings and persists them.
2. pr-tracker-api: provides an HTTP endpoint for querying landings
