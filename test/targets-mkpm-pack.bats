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

@test "mkpm-pack with default main" {
  printf 'name=pkg\nversion=1.1.1\n' > "$FIXTURE/mkpkg"
  run --keep-empty-lines "${MAKE:-make}" --no-print-directory -C "$FIXTURE" mkpm-pack
  assert_success
  assert_file_exists "$FIXTURE/pkg@1.1.1.tgz"
  run tar -xvf "$FIXTURE/pkg@1.1.1.tgz" -C "$BATS_TEST_TMPDIR"
  assert_file_exists "$BATS_TEST_TMPDIR/Makefile"
}

@test "mkpm-pack with custom main" {
  printf 'name=pkg\nversion=1.1.1\nmain=custom.mk' > "$FIXTURE/mkpkg"
  printf 'var := hello' > "$FIXTURE/custom.mk"
  run --keep-empty-lines "${MAKE:-make}" --no-print-directory -C "$FIXTURE" mkpm-pack
  assert_success
  assert_file_exists "$FIXTURE/pkg@1.1.1.tgz"
  run tar -xvf "$FIXTURE/pkg@1.1.1.tgz" -C "$BATS_TEST_TMPDIR"
  assert_file_exists "$BATS_TEST_TMPDIR/custom.mk"
}

@test "mkpm-pack with defined assets" {
  printf 'name=pkg\nversion=1.1.1\nassets=file.example' > "$FIXTURE/mkpkg"
  printf 'hello' > "$FIXTURE/file.example"
  run --keep-empty-lines "${MAKE:-make}" --no-print-directory -C "$FIXTURE" mkpm-pack
  assert_success
  assert_file_exists "$FIXTURE/pkg@1.1.1.tgz"
  run tar -xvf "$FIXTURE/pkg@1.1.1.tgz" -C "$BATS_TEST_TMPDIR"
  assert_file_exists "$BATS_TEST_TMPDIR/file.example"
}
