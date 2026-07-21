#!/usr/bin/env bash
# test/test_helper.bash — shared setup for every .bats file.
bats_require_minimum_version 1.5.0

# Load the assertion libraries (resolved relative to this test directory).
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/bats-file/load'

# # All fixtures use paths relative to the project root (modules/, make/),
# # so every test runs make from there. BATS_TEST_DIRNAME is the test/ dir.
# setup() {
#   PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
#   cd "$PROJECT_ROOT" || return 1
# }

# Convenience wrapper: `make_fixture net.mk print-net_OBJS`
make_fixture() {
  local fixture="$1"; shift
  local envs=() has_sep=0 tok
  for tok in "$@"; do [ "$tok" = '--' ] && { has_sep=1; break; }; done
  if [ "$has_sep" -eq 1 ]; then
    while [ "$#" -gt 0 ] && [ "$1" != '--' ]; do envs+=("$1"); shift; done
    shift   # drop the --
  fi
  run env ${envs[@]+"${envs[@]}"} make -f "test/fixtures/${fixture}" "$@"
}
