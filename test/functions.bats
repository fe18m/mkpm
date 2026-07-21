#!/usr/bin/env bats
# test/modules.bats
#
# Run with:  ./run-tests.sh        (from project root)
#       or:  test/bats/bin/bats test/modules.bats

load 'test_helper'

setup() {
  FIXTURES="test/fixtures"
}

teardown() {
  rm -rf "$FIXTURES/functions/.mkpm_plugins"
}

@test "_mkpm_is_rel_dir returns truthy when relative" {
  run --keep-empty-lines "${MAKE:-make}" --no-print-directory -C "$FIXTURES/functions" expand-_mkpm_is_rel_dir a1=../relative/path
  assert_output 't'
}

@test "_mkpm_is_rel_dir returns falsy when absolute" {
  run --keep-empty-lines "${MAKE:-make}" --no-print-directory -C "$FIXTURES/functions" expand-_mkpm_is_rel_dir a1=/absolute/path
  assert_output ''
}

@test "_mkpm_sanitize_config_contents returns a=b when a =b" {
  run "${MAKE:-make}" --no-print-directory -C "$FIXTURES/functions" expand-_mkpm_sanitize_config_contents a1="a =b"
  assert_success
  assert_output 'a=b'
}

@test "_mkpm_sanitize_config_contents returns a=b when a= b" {
  run "${MAKE:-make}" --no-print-directory -C "$FIXTURES/functions" expand-_mkpm_sanitize_config_contents a1="a= b"
  assert_success
  assert_output 'a=b'
}

@test "_mkpm_sanitize_config_contents returns a=b when a    =     b" {
  run "${MAKE:-make}" --no-print-directory -C "$FIXTURES/functions" expand-_mkpm_sanitize_config_contents a1="a    =     b"
  assert_success
  assert_output 'a=b'
}

@test "_mkpm_sanitize_config_contents returns a=b when a    =     b  c  d      e" {
  run "${MAKE:-make}" --no-print-directory -C "$FIXTURES/functions" expand-_mkpm_sanitize_config_contents a1="a    =     b  c  d      e"
  assert_success
  assert_output 'a=b c d e'
}

@test "_mkpm_get returns value from key" {
  run "${MAKE:-make}" --no-print-directory -C "$FIXTURES/functions" expand-_mkpm_get a2=c a1="a =   b c=d"
  assert_output 'd'
}


@test "mkpm_pkg_main returns pkg entrypoint" {
  printf "name=example\nmain=main.mk" > "$FIXTURES/functions/mkpkg"
  run "${MAKE:-make}" --no-print-directory -C "$FIXTURES/functions" expand-_mkpm_pkg_main
  assert_success
  assert_output 'main.mk'
  rm -f "$FIXTURES/functions/mkpkg"
}

@test "mkpm_pkg_main without a mkpkg file defaults to Makefile" {
  run "${MAKE:-make}" --no-print-directory -C "$FIXTURES/functions" expand-_mkpm_pkg_main
  assert_success
  assert_output 'Makefile'
}

@test "_mkpm_mkpmrc_get get a key from mkpmrc file" {
  mv "$FIXTURES"/functions/.mkpmrc "$FIXTURES"/functions/.mkpmrc.tmp
  printf "reg=example" > "$FIXTURES/functions/.mkpmrc"
  printf "reg=ghcr.io/codextremist\nmkpm_dir=../../.." > "$FIXTURES/functions/.mkpmrc.local"
  run "${MAKE:-make}" --no-print-directory -C "$FIXTURES/functions" expand-_mkpm_mkpmrc_get a1=reg
  assert_output 'ghcr.io/codextremist'
  rm -f "$FIXTURES/functions/.mkpmrc" "$FIXTURES/functions/.mkpmrc.local"
  mv "$FIXTURES"/functions/.mkpmrc.tmp "$FIXTURES"/functions/.mkpmrc
}

@test "_mkpm_mkpkg_get with non-default mkpkg path" {
  mkdir -p "$FIXTURES/functions/non-default"
  printf "name=example" > "$FIXTURES/functions/non-default/mkpkg"
  run --keep-empty-lines "${MAKE:-make}" --no-print-directory -C "$FIXTURES/functions" expand-_mkpm_mkpkg_get a1=name a2="non-default"
  assert_output 'example'
  rm -rf "$FIXTURES/functions/non-default"
}

@test "_mkpm_write_config_file" {
  run --keep-empty-lines "${MAKE:-make}" --no-print-directory -C "$FIXTURES/functions" expand-_mkpm_write_config_file a1=test.txt a2="a=b c=d e=f"
  run cat "$FIXTURES/functions/test.txt"
  assert_line --index 0 'a=b'
  assert_line --index 1 'c=d'
  assert_line --index 2 'e=f'
  run rm -f "$FIXTURES/functions/test.txt"
}

@test "_mkpm_mkpkg_set" {
  printf "version=0.0.1" > "$FIXTURES/functions/mkpkg"
  run --keep-empty-lines "${MAKE:-make}" --no-print-directory -C "$FIXTURES/functions" expand-_mkpm_mkpkg_set a1=version a2="1.0.0"
  run cat "$FIXTURES/functions/mkpkg"
  assert_output 'version=1.0.0'
  rm -f "$FIXTURES/functions/mkpkg"
}

@test "_mkpm_semver_major" {
  printf "version=1.0.0" > "$FIXTURES/functions/mkpkg"
  run --keep-empty-lines "${MAKE:-make}" --no-print-directory -C "$FIXTURES/functions" expand-"$BATS_TEST_DESCRIPTION"
  assert_output '1'
  run rm -f "$FIXTURES/functions/mkpkg"
}

@test "_mkpm_semver_minor" {
  printf "version=1.1.1" > "$FIXTURES/functions/mkpkg"
  run --keep-empty-lines "${MAKE:-make}" --no-print-directory -C "$FIXTURES/functions" expand-"$BATS_TEST_DESCRIPTION"
  assert_output '1'
  run rm -f "$FIXTURES/functions/mkpkg"
}

@test "_mkpm_semver_patch" {
  printf "version=1.1.1" > "$FIXTURES/functions/mkpkg"
  run --keep-empty-lines "${MAKE:-make}" --no-print-directory -C "$FIXTURES/functions" expand-"$BATS_TEST_DESCRIPTION"
  assert_output '1'
  run rm -f "$FIXTURES/functions/mkpkg"
}

@test "_mkpm_ws" {
  mv "$FIXTURES"/functions/.mkpmrc "$FIXTURES"/functions/.mkpmrc.tmp
  printf "ws=./\nmkpm_dir=../../.." > "$FIXTURES/functions/.mkpmrc"
  run --keep-empty-lines "${MAKE:-make}" --no-print-directory -C "$FIXTURES/functions" expand-_mkpm_ws
  assert_output './'
  rm -f "$FIXTURES/functions/.mkpmrc" "$FIXTURES/functions/.mkpmrc.local"
  mv "$FIXTURES"/functions/.mkpmrc.tmp "$FIXTURES"/functions/.mkpmrc
}

@test "_mkpm_plugins loads default plugins" {
  run --keep-empty-lines "${MAKE:-make}" --no-print-directory -C "$FIXTURES/functions" expand-_mkpm_plugins
  assert_output '+mkpm-oras'
}

@test "_mkpm_plugins loads plugins defined on .mkpmrc" {
  mv "$FIXTURES"/functions/.mkpmrc "$FIXTURES"/functions/.mkpmrc.tmp
  printf "plugins=+mkpm-oras\nmkpm_dir=../../.." > "$FIXTURES/functions/.mkpmrc"
  run --keep-empty-lines "${MAKE:-make}" --no-print-directory -C "$FIXTURES/functions" expand-_mkpm_plugins
  assert_output '+mkpm-oras'
  rm -f "$FIXTURES/functions/.mkpmrc"
  mv "$FIXTURES"/functions/.mkpmrc.tmp "$FIXTURES"/functions/.mkpmrc
}

@test "_mkpm_ws_dir returns absolute dir when ws is relative" {
  mv "$FIXTURES"/functions/.mkpmrc "$FIXTURES"/functions/.mkpmrc.tmp
  printf "ws=./\nmkpm_dir=../../.." > "$FIXTURES/functions/.mkpmrc"
  run --keep-empty-lines "${MAKE:-make}" --no-print-directory -C "$FIXTURES/functions" expand-_mkpm_ws_dir
  assert_output "$PWD/$FIXTURES/functions"
  rm -f "$FIXTURES/functions/.mkpmrc"
  mv "$FIXTURES"/functions/.mkpmrc.tmp "$FIXTURES"/functions/.mkpmrc
}

@test "_mkpm_ws_dir returns dir when ws is absolute" {
  mv "$FIXTURES"/functions/.mkpmrc "$FIXTURES"/functions/.mkpmrc.tmp
  printf "ws=/a/b/c\nmkpm_dir=../../.." > "$FIXTURES/functions/.mkpmrc"
  run --keep-empty-lines "${MAKE:-make}" --no-print-directory -C "$FIXTURES/functions" expand-_mkpm_ws_dir
  assert_output "/a/b/c"
  rm -f "$FIXTURES/functions/.mkpmrc"
  mv "$FIXTURES"/functions/.mkpmrc.tmp "$FIXTURES"/functions/.mkpmrc
}

@test "_mkpm_is_pkg_loaded returns thruthy when pkg was already loaded" {
  run --keep-empty-lines "${MAKE:-make}" --no-print-directory -C "$FIXTURES/functions" expand-_mkpm_is_pkg_loaded _mkpm_loaded_pkgs="pkg-a" a1="pkg-a"
  assert_output "pkg-a"
}

@test "_mkpm_is_pkg_loaded returns falsy when pkg was not already loaded" {
  run --keep-empty-lines "${MAKE:-make}" --no-print-directory -C "$FIXTURES/functions" expand-_mkpm_is_pkg_loaded a1="pkg-a"
  assert_output ""
}

@test "_mkpm_is_pkg_in_ws returns falsy when pkg is not in workspace" {
  mv "$FIXTURES"/functions/.mkpmrc "$FIXTURES"/functions/.mkpmrc.tmp
  printf "ws=./ws\nmkpm_dir=../../.." > "$FIXTURES/functions/.mkpmrc"
  run mkdir -p "$FIXTURES/functions/ws"
  run --keep-empty-lines "${MAKE:-make}" --no-print-directory -C "$FIXTURES/functions" expand-_mkpm_is_pkg_in_ws a1="pkg-a"
  assert_output ""
  rm -rf "$FIXTURES/functions/ws"
  rm -f "$FIXTURES/functions/.mkpmrc"
  mv "$FIXTURES"/functions/.mkpmrc.tmp "$FIXTURES"/functions/.mkpmrc
}

@test "_mkpm_is_pkg_in_ws returns truthy when pkg is in workspace" {
  mv "$FIXTURES"/functions/.mkpmrc "$FIXTURES"/functions/.mkpmrc.tmp
  printf "ws=./ws\nmkpm_dir=../../.." > "$FIXTURES/functions/.mkpmrc"
  run mkdir -p "$FIXTURES/functions/ws/pkg-a"
  run --keep-empty-lines "${MAKE:-make}" --no-print-directory -C "$FIXTURES/functions" expand-_mkpm_is_pkg_in_ws a1="pkg-a"
  assert_line --regexp '/ws/pkg-a$'
  run rm -rf "$FIXTURES/functions/ws"
  rm -f "$FIXTURES/functions/.mkpmrc"
  mv "$FIXTURES"/functions/.mkpmrc.tmp "$FIXTURES"/functions/.mkpmrc
}

@test "_mkpm_unpack_files unpacks a pack file" {
  run mkdir -p "$FIXTURES/functions/.mkpkgs/pkg@1.0.0"
  run --keep-empty-lines "${MAKE:-make}" --no-print-directory -C "$FIXTURES/functions" expand-_mkpm_unpack_files a1="pkg@1.0.0"
  assert_output 'tar -xf pkg@1.0.0.tgz -C .mkpkgs/pkg@1.0.0'
}