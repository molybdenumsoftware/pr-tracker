## [7.2.0](https://github.com/molybdenumsoftware/pr-tracker/compare/v7.1.0...v7.2.0) (2025-05-20)


### Features

* **api:** request response tracing ([c1e6d4a](https://github.com/molybdenumsoftware/pr-tracker/commit/c1e6d4ae4f75426ae6b8537ac26694518efc680a)), closes [#247](https://github.com/molybdenumsoftware/pr-tracker/issues/247) [#249](https://github.com/molybdenumsoftware/pr-tracker/issues/249)

## [7.1.0](https://github.com/molybdenumsoftware/pr-tracker/compare/v7.0.0...v7.1.0) (2025-05-20)


### Features

* **api:** tracing ([e40efb9](https://github.com/molybdenumsoftware/pr-tracker/commit/e40efb940011ed39cfda440bebab75272bc64be6))

## [7.0.0](https://github.com/molybdenumsoftware/pr-tracker/compare/v6.2.0...v7.0.0) (2025-04-30)


### ⚠ BREAKING CHANGES

* **api:** remove /api/v1 and add /api/v2
* **api:** return 204 when no PR is found

### Features

* **api:** remove /api/v1 and add /api/v2 ([9216afc](https://github.com/molybdenumsoftware/pr-tracker/commit/9216afc13eb6e7e67fc6ec3665ba170bee79a7b1))
* **api:** return 204 when no PR is found ([057cb0c](https://github.com/molybdenumsoftware/pr-tracker/commit/057cb0cf209121783727e0f2c965cdba8bc95738))

## [6.2.0](https://github.com/molybdenumsoftware/pr-tracker/compare/v6.1.0...v6.2.0) (2025-04-25)


### Features

* openapi with swagger ui ([1bf9d2c](https://github.com/molybdenumsoftware/pr-tracker/commit/1bf9d2cfba257365af89226d3c1cc53a9b8ba47c)), closes [#188](https://github.com/molybdenumsoftware/pr-tracker/issues/188)

## [6.1.0](https://github.com/molybdenumsoftware/pr-tracker/compare/v6.0.0...v6.1.0) (2025-01-08)


### Features

* **flake:** no experimental features ([e324e34](https://github.com/molybdenumsoftware/pr-tracker/commit/e324e3499bdb620af8b7228a2e85ba3fde69a24e))

## [6.0.0](https://github.com/molybdenumsoftware/pr-tracker/compare/v5.1.0...v6.0.0) (2024-12-31)


### ⚠ BREAKING CHANGES

* override mechanism from nixpkgs replaced by
that of dream2nix

### Miscellaneous Chores

* use nix-cargo-integration ([3c61682](https://github.com/molybdenumsoftware/pr-tracker/commit/3c616822196ad3da864a1c13d1a01a3d4f44cd53))

## [5.1.0](https://github.com/molybdenumsoftware/pr-tracker/compare/v5.0.0...v5.1.0) (2024-12-17)


### Features

* switch from AGPL to MIT. ([44a1019](https://github.com/molybdenumsoftware/pr-tracker/commit/44a10199964cd2d2975cf2b0b5b3f7e006730739))

## [5.0.0](https://github.com/molybdenumsoftware/pr-tracker/compare/v4.1.1...v5.0.0) (2024-12-11)


### ⚠ BREAKING CHANGES

* runtime deps defined at build time

### Features

* runtime deps defined at build time ([08196d1](https://github.com/molybdenumsoftware/pr-tracker/commit/08196d1025c294dadca7632b93b526012d638061))

## [4.1.1](https://github.com/molybdenumsoftware/pr-tracker/compare/v4.1.0...v4.1.1) (2024-10-02)


### Bug Fixes

* nixos docs now deploy ([996f96c](https://github.com/molybdenumsoftware/pr-tracker/commit/996f96cc836bb42022eeb99567ef5689ab6095e3))

## [4.1.0](https://github.com/molybdenumsoftware/pr-tracker/compare/v4.0.0...v4.1.0) (2024-10-02)


### Features

* **flake:** NixOS modules have key and _file ([2564acf](https://github.com/molybdenumsoftware/pr-tracker/commit/2564acf1ed3c46f4fb9615c57f033b071a5eebee))

## [4.0.0](https://github.com/molybdenumsoftware/pr-tracker/compare/v3.0.0...v4.0.0) (2024-10-01)


### ⚠ BREAKING CHANGES

* **flake:** rm empty nixosModules.common

### Miscellaneous Chores

* **flake:** rm empty nixosModules.common ([c5c573e](https://github.com/molybdenumsoftware/pr-tracker/commit/c5c573e4dce4ae2ff3335282f4651fa28ab9d508))

## [3.0.0](https://github.com/molybdenumsoftware/pr-tracker/compare/v2.0.0...v3.0.0) (2024-04-19)


### ⚠ BREAKING CHANGES

* **flake:** db options attrset

### Features

* **flake:** db options attrset ([97347a9](https://github.com/molybdenumsoftware/pr-tracker/commit/97347a9c1d06e841bdaab297c9782d4ca335fcff))
* **flake:** db.createLocally ([3e71d93](https://github.com/molybdenumsoftware/pr-tracker/commit/3e71d93526ba72654af854750ca6d7a57ea40548)), closes [#116](https://github.com/molybdenumsoftware/pr-tracker/issues/116)

## [2.0.0](https://github.com/molybdenumsoftware/pr-tracker/compare/v1.0.1...v2.0.0) (2024-03-25)


### ⚠ BREAKING CHANGES

* **flake:** services.pr-tracker attrset

### Features

* **flake:** services.pr-tracker attrset ([d41a694](https://github.com/molybdenumsoftware/pr-tracker/commit/d41a69455e356466e9fa9e2ae381bcb419b946d5))

## [1.0.1](https://github.com/molybdenumsoftware/pr-tracker/compare/v1.0.0...v1.0.1) (2024-03-21)


### Bug Fixes

* **flake:** executable derivations have version ([f21c35a](https://github.com/molybdenumsoftware/pr-tracker/commit/f21c35a416a0b63ea6c7c8a7a62880f1b7b8c0aa))
