#!/usr/bin/env bash
set -euo pipefail

# Contract checker for command availability.
#
# Usage:
#   ./commands-on-path.sh cmd1 cmd2 ...

missing=0
for cmd in "$@"; do
	if ! command -v "$cmd" >/dev/null 2>&1; then
		echo "missing command: $cmd" >&2
		missing=1
	fi
done

test "$missing" -eq 0
