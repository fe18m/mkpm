#!/usr/bin/env bash
# run-tests.sh — run the whole Bats suite from the project root.
set -euo pipefail
cd "$(dirname "$0")"

if [ "$(uname -s)" = Darwin ] && command -v gmake >/dev/null; then
  export MAKE="${MAKE:-gmake}"
fi

exec test/bats/bin/bats "${@:-test/}"
