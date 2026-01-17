#!/usr/bin/env bash
set -euo pipefail

# Compatibility wrapper: the single implementation lives in ../guards/helix-guard.sh

exec "$(dirname "${BASH_SOURCE[0]}")/../guards/helix-guard.sh" check-xdg
