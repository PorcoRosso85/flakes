#!/usr/bin/env bash
set -euo pipefail

# Contract checker for `hx --health` output.
#
# - No CLI args (required commands must not be hand-passed)
# - ANSI is stripped before matching
# - Only fails if required commands are reported missing
#
# Usage:
#   export HELIX_REQUIRED_COMMANDS_FILE=/path/to/required.txt
#   hx --health 2>&1 | ./hx-health-contract.sh

: "${HELIX_REQUIRED_COMMANDS_FILE:?missing HELIX_REQUIRED_COMMANDS_FILE (required commands injection)}"

out="$(cat)"

# Strip ANSI colors (best-effort)
clean="$(printf '%s' "$out" | sed -r 's/\x1B\[[0-9;]*[mK]//g')"

missing=0
while IFS= read -r cmd || [[ -n "$cmd" ]]; do
	[[ -z "$cmd" ]] && continue

	needle1="'${cmd}' not found in \$PATH"
	needle2="${cmd} not found in \$PATH"

	if [[ "$clean" == *"$needle1"* || "$clean" == *"$needle2"* ]]; then
		echo "hx --health reported missing required command: ${cmd}" >&2
		missing=1
	fi
done <"$HELIX_REQUIRED_COMMANDS_FILE"

if [[ "$missing" -ne 0 ]]; then
	printf '%s\n' "$clean" >&2
	exit 1
fi

exit 0
