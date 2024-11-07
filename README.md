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

Intended to be periodically executed.
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

## Prior art

- [Alyssa Ross' pr-tracker](https://nixpk.gs/pr-tracker.html) ([source](https://git.qyliss.net/pr-tracker))
  Server-side rendered web app. Computes landings for a given PR on the fly by invoking Git on the backend.
- [ocfox's nixpkgs-tracker](https://nixpkgs-tracker.ocfox.me/) ([source](https://github.com/ocfox/nixpkgs-tracker))
  Client-side rendered web app. Computes landings for a given PR on the fly using GitHub api.
- [Maralorn's nixpkgs-bot](https://blog.maralorn.de/projects#nixpkgs-bot) ([source](https://code.maralorn.de/maralorn/config/src/commit/b34d2e0d0adc62c30875edb475f1c09a752fe19e/packages/nixpkgs-bot))
  Matrix bot that provides notification of PR landings.
  Periodically computes new PR landings using Git and sends messages.

All of the above are [Nixpkgs](https://github.com/nixos/nixpkgs/) specific, whereas this project is not.
None of the above internally maintain a dataset of landings.
None of the above currently provide an HTTP API.

## Vision

### Push-driven updates

The current architecture of obtaining data via polling allows instantaneous
and hopefully reliable responses.
However, the data can be stale.

In the future, we intend to provide fresher data by subscribing to GitHub webhooks.

Since the public cannot subscribe to GitHub webhooks,
this will require deployment by the repo owner.

### Event record keeping

Building upon the implementation of push-driven updates,
we intend to keep track of _when_ PRs land in branches.
This requires a dataset of landings.

### Webhook service

We intend to allow users to subscribe to webhook notifications of PR landings.
This provides a couple of benefits over subscribing to GitHub webhooks directly:

- GitHub webhooks can only notify when a PR lands in its target branch. They
  cannot notify when that PR lands in other branches.
- Only repo owners can subscribe to GitHub webhooks.

### Backport PRs

A backport PR is a re-application of another PR, targeting a different branch.

We intend to adopt or invent a workflow whereby in backport PRs the original PR is declared.
Using that metadata, when providing landings for an original PR,
we intend to also include branches on which a backport PR had landed.
