#!/usr/bin/env bash
set -euo pipefail

# Python smoke: minimal project in TMPDIR, then `opencode debug lsp diagnostics` returns non-empty.

contract="${OPENCODE_OUTPUT_CONTRACT:-}"
if [[ -z "$contract" ]]; then
	script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	if [[ -f "$script_dir/output-contract.sh" ]]; then
		contract="$script_dir/output-contract.sh"
	fi
fi

if [[ -z "$contract" ]]; then
	echo "missing OPENCODE_OUTPUT_CONTRACT (output-contract.sh)" >&2
	exit 1
fi

# shellcheck source=/dev/null
source "$contract"

workdir="$(mktemp -d "${TMPDIR:-/tmp}/opencode-python-lsp.XXXXXXXX")"
cd "$workdir"

cat >pyrightconfig.json <<'JSON'
{
  "typeCheckingMode": "strict"
}
JSON

cat >main.py <<'PY'
# Intentional errors
x: int = "a"
print(unknown_name)
PY

retries="${OPENCODE_LSP_SMOKE_RETRIES:-15}"
sleep_s="${OPENCODE_LSP_SMOKE_SLEEP_S:-0.4}"

out=""
for i in $(seq 1 "$retries"); do
	out="$(opencode debug lsp diagnostics main.py 2>/dev/null || true)"
	if assert_diagnostics_nonempty "$out"; then
		exit 0
	fi
	sleep "$sleep_s"
done

echo "python-lsp-smoke failed after ${retries} tries" >&2
echo "last output:" >&2
printf '%s\n' "$out" >&2
exit 1
