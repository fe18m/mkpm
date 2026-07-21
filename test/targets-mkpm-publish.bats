#!/usr/bin/env bats
# test/modules.bats
#
# Run with:  ./run-tests.sh        (from project root)
#       or:  test/bats/bin/bats test/modules.bats

load 'test_helper'

setup() {
  FIXTURE="$BATS_TEST_DIRNAME/fixtures/targets"
}

teardown() {
  rm -f "$FIXTURE"/mkpkg 
  rm -f "$FIXTURE"/*.tgz
  rm -f "$FIXTURE"/*.example
}

@test "mkpm-publish" {
  printf 'name=pkg\nversion=1.0.0\n' > "$FIXTURE/mkpkg"
  run --keep-empty-lines "${MAKE:-make}" --no-print-directory -C "$FIXTURE" mkpm-publish
  assert_success
}

# @test "mkpm-publish without plugins" {
#   printf 'reg=ghcr.io/codextremist' > test/fixtures/.mkpmrc
#   printf 'name=pkg\nversion=1.0.0\n' > test/fixtures/mkpkg
#   make_fixture Makefile -- mkpm-publish
#   assert_failure
# }