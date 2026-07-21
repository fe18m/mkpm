#!/usr/bin/env bats
# test/modules.bats
#
# Run with:  ./run-tests.sh        (from project root)
#       or:  test/bats/bin/bats test/modules.bats

load 'test_helper'

setup() {
  FIXTURE="$BATS_TEST_DIRNAME/fixtures/targets"
  printf 'version=1.0.0\n' > "$FIXTURE/mkpkg"
}

teardown() {
  rm -f "$FIXTURE/mkpkg"
}

@test "mkpm-semver-bump" {
  run --keep-empty-lines "${MAKE:-make}" --no-print-directory -C "$FIXTURE" mkpm-semver-bump ver="1.5.3"
  assert_success
  run cat "$FIXTURE/mkpkg"
  assert_output "version=1.5.3"
}

@test "mkpm-semver-patch" {
  run --keep-empty-lines "${MAKE:-make}" --no-print-directory -C "$FIXTURE" mkpm-semver-patch
  assert_success
  run cat "$FIXTURE/mkpkg"
  assert_output 'version=1.0.1'
}

@test "mkpm-semver-minor" {
  run --keep-empty-lines "${MAKE:-make}" --no-print-directory -C "$FIXTURE" mkpm-semver-minor
  assert_success
  run cat "$FIXTURE/mkpkg"
  assert_output 'version=1.1.0'
}

@test "mkpm-semver-major" {
  run --keep-empty-lines "${MAKE:-make}" --no-print-directory -C "$FIXTURE" mkpm-semver-major
  assert_success
  run cat "$FIXTURE/mkpkg"
  assert_output 'version=2.0.0'
}