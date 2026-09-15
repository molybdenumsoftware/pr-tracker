{ lib, fetchFromGitHub }:
let
  flakeLock = lib.importJSON ../../flake.lock;
  inherit (flakeLock.nodes.octokit-graphql-schema) locked;
in
fetchFromGitHub {
  inherit (locked) owner repo rev;
  hash = locked.narHash;
}
