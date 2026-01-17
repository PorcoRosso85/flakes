#!/usr/bin/env bash
set -euo pipefail

# DoD: forbid `$XDG_CONFIG_HOME/helix/languages.toml -> /nix/store/...`.
#
# This is a reoccurrence guard for "single reference point".

: "${XDG_CONFIG_HOME:?XDG_CONFIG_HOME must be set}"

p="$XDG_CONFIG_HOME/helix/languages.toml"

# Nothing to check if absent.
if [[ ! -e "$p" ]]; then
	exit 0
fi

# Must not be a real file.
if [[ -e "$p" && ! -L "$p" ]]; then
	echo "forbidden: XDG languages.toml must be a symlink" >&2
	exit 1
fi

# If it's a symlink, it must not point directly into /nix/store.
target="$(readlink "$p")"
if [[ "$target" == /nix/store/* ]]; then
	echo "forbidden: XDG languages.toml must not point directly to nix store: $target" >&2
	exit 1
fi

exit 0
