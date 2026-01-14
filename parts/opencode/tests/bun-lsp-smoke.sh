#!/usr/bin/env bash
set -euo pipefail

# TS/JS smoke: minimal project in TMPDIR, then `opencode debug lsp diagnostics` returns non-empty.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=output-contract.sh
source "$SCRIPT_DIR/output-contract.sh"

workdir="$(mktemp -d "${TMPDIR:-/tmp}/opencode-bun-lsp.XXXXXXXX")"
cd "$workdir"

cat >tsconfig.json <<'JSON'
{
  "compilerOptions": {
    "strict": true,
    "target": "ES2020",
    "module": "ESNext"
  }
}
JSON

cat >index.ts <<'TS'
// Intentional type error
const x: number = "a";
console.log(x);
TS

retries="${OPENCODE_LSP_SMOKE_RETRIES:-15}"
sleep_s="${OPENCODE_LSP_SMOKE_SLEEP_S:-0.4}"

out=""
for i in $(seq 1 "$retries"); do
	out="$(opencode debug lsp diagnostics index.ts 2>/dev/null || true)"
	if assert_diagnostics_nonempty "$out"; then
		exit 0
	fi
	sleep "$sleep_s"
done

echo "bun-lsp-smoke failed after ${retries} tries" >&2
echo "last output:" >&2
printf '%s\n' "$out" >&2
exit 1
