#!/usr/bin/env bash
set -euo pipefail

# Contract checker for `hx --health` output.
#
# Usage:
#   hx --health 2>&1 | ./hx-health-contract.sh

out="$(cat)"

# Fail on any PATH-missing report.
if printf '%s' "$out" | grep -q "not found in \$PATH"; then
	echo "hx --health reported missing commands" >&2
	printf '%s\n' "$out" >&2
	exit 1
fi

exit 0
