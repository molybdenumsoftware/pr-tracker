# pr-tracker

## What

This is a system that provides answers to the following question:

> Which branches did a certain GitHub pull request "land" in?

A pull request is considered landed in a branch when that branch contains that pull request's "merge commit"[^1].

As of 2024-02-02 GitHub does not provide an API for directly asking this question.

## How

In order to provide an API that answers this question the following are obtained:

1. All pull requests and their merge commits (via GitHub's GraphQL API).
2. A clone of the repository.

From these, all landings are deduced and stored in a (PostgreSQL) database.

It is assumed that in the tracked branches, history is never rewritten. 

Two programs are provided:

1. pr-tracker-fetcher: obtains data, determines landings and persists them.
2. pr-tracker-api: provides an HTTP endpoint for querying landings.

## pr-tracker-fetcher

Takes no arguments.
Expects [configuration via environment](https://molybdenumsoftware.github.io/pr-tracker/programs/pr_tracker_fetcher_config/struct.Environment.html).

## pr-tracker-api

Takes no arguments.
Expects [configuration via environment](https://molybdenumsoftware.github.io/pr-tracker/programs/pr_tracker_api_config/struct.Environment.html).

## NixOS modules

[Manual](https://molybdenumsoftware.github.io/pr-tracker/nixos-modules)

## Versioning

- This project uses [Conventional Commits v1](https://www.conventionalcommits.org/en/v1.0.0/) and [Semantic Versioning v2](https://semver.org/spec/v2.0.0.html).
- With regard to versioning, the documented executables and NixOS modules are public.
  The libraries are private.
- This project, with all its components, is versioned as one.

[^1]: Note that in GitHub, a pull request has a "merge commit" even having been merged without an actual merge commit.
