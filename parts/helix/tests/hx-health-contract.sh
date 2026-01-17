#!/usr/bin/env bash
set -euo pipefail

# Contract checker for `hx --health` output.
#
# We intentionally do NOT fail on missing built-in servers.
# We only fail if commands provided as args are reported missing.
#
# Usage:
#   hx --health 2>&1 | ./hx-health-contract.sh cmd1 cmd2 ...

out="$(cat)"

for cmd in "$@"; do
	needle1="'${cmd}' not found in \$PATH"
	needle2="${cmd} not found in \$PATH"

	if [[ "$out" == *"$needle1"* || "$out" == *"$needle2"* ]]; then
		echo "hx --health reported missing required command: ${cmd}" >&2
		printf '%s\n' "$out" >&2
		exit 1
	fi
done

exit 0
