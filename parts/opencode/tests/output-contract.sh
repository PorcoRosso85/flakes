#!/usr/bin/env bash
set -euo pipefail

# Output contract for `opencode debug lsp diagnostics`.
#
# Rules (must stay stable):
# - Empty / `{}` / `[]` => FAIL
# - If JSON: PASS when any diagnostics-like signal exists
#   - any non-empty array anywhere
#   - OR any object contains keys like "severity" or "range"
# - If not JSON: PASS when output contains "severity" or "range"

is_effectively_empty() {
	local out="$1"
	# trim whitespace
	out="$(printf '%s' "$out" | tr -d ' \t\r\n')"
	[[ -z "$out" || "$out" == "{}" || "$out" == "[]" ]]
}

assert_diagnostics_nonempty() {
	local out="$1"

	if is_effectively_empty "$out"; then
		echo "diagnostics output is empty" >&2
		return 1
	fi

	if command -v jq >/dev/null 2>&1; then
		if printf '%s' "$out" | jq -e . >/dev/null 2>&1; then
			# JSON path
			if printf '%s' "$out" | jq -e '
        (any(.. | arrays; length > 0))
        or
        (any(.. | objects; (has("severity") or has("range"))))
      ' >/dev/null 2>&1; then
				return 0
			fi

			echo "diagnostics JSON parsed but no signal found" >&2
			return 1
		fi
	fi

	# Non-JSON fallback
	if printf '%s' "$out" | grep -qE '"severity"|"range"'; then
		return 0
	fi

	echo "diagnostics output not JSON and no key match" >&2
	return 1
}
