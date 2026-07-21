#!/usr/bin/env bats
# test/modules.bats
#
# Run with:  ./run-tests.sh        (from project root)
#       or:  test/bats/bin/bats test/modules.bats

load 'test_helper'

setup() {
  FIXTURES="test/fixtures"
}


@test "loads a local pkg" {
  run --keep-empty-lines "${MAKE:-make}" --no-print-directory -C "$FIXTURES/mkpm-load-local-pkg" pkg-a-target
  assert_success
  assert_output "Hello World"
}

@test "when assets are declared, copy each asset to CURDIR when loading local packages" {
  CURDIR="$FIXTURES/mkpm-load-local-pkg-with-assets"
  run --keep-empty-lines "${MAKE:-make}" --no-print-directory -C "$FIXTURES/mkpm-load-local-pkg-with-assets" pkg-a-target
  assert_success
  assert_file_exists "$CURDIR/file-a.txt"
  assert_file_exists "$CURDIR/some-dir/file-b.txt"
  run cat "$CURDIR/file-a.txt"
  assert_output "Hello World"
  run rm -f "$CURDIR/file-a.txt"
  run rm -f "$CURDIR/some-dir/file-b.txt"
}

@test "pkg-a is only loaded once" {
  run --keep-empty-lines "${MAKE:-make}" --no-print-directory -C "$FIXTURES/mkpm-load-only-once" print-_mkpm_loaded_pkgs
  assert_success
  assert_output '_mkpm_loaded_pkgs = pkg-a'
}

@test "try downloading remote pkg if local not found" {
  CURDIR="$FIXTURES/mkpm-load-nonexistent-local-pkg"
  run cp "$CURDIR/pkg-not-found.tgz" "$CURDIR/pkg-not-found.tgz.tmp"
  printf 'reg=ghcr.io/codextremist' > "$CURDIR/.mkpmrc"
  run --keep-empty-lines "${MAKE:-make}" --no-print-directory -C "$CURDIR"
  assert_line --index 0 'Downloading package pkg-not-found...'
  run mv "$CURDIR/pkg-not-found.tgz.tmp" "$CURDIR/pkg-not-found.tgz"
  run rm -rf "$CURDIR/.mkpkgs"
}

@test "load remote pkg" {
  CURDIR="$FIXTURES/mkpm-load-remote-pkg"
  run rm -rf "$CURDIR/.mkpkgs"
  run cp "$CURDIR/downloaded-pkg@1.0.0.tgz" "$CURDIR/downloaded-pkg@1.0.0.tgz.copy"
  run --keep-empty-lines "${MAKE:-make}" --no-print-directory -C "$CURDIR" hello-world
  assert_success
  assert_file_exists 'test/fixtures/mkpm-load-remote-pkg/.mkpkgs/downloaded-pkg@1.0.0/Makefile'
  assert_file_exists 'test/fixtures/mkpm-load-remote-pkg/.mkpkgs/downloaded-pkg@1.0.0/mkpkg'
  assert_output 'Hello World'
  run mv "$CURDIR/downloaded-pkg@1.0.0.tgz.copy" "$CURDIR/downloaded-pkg@1.0.0.tgz"
}