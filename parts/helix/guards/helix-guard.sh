#!/usr/bin/env bash
set -euo pipefail

# Single-source guard implementation for Helix devShell.
#
# Responsibilities (DRY: implemented only here):
# - 2-step .helix symlink contract
# - forbid XDG_CONFIG_HOME/helix/languages.toml -> /nix/store/*
# - ensure XDG side references $PWD/.helix only
#
# Inputs (env):
#   HELIX_GUARD_STORE_LANGUAGES_TOML   required for `apply`
#   HELIX_GUARD_XDG_CONFIG_HOME        optional for `apply` (defaults to $XDG_CONFIG_HOME)
#   HELIX_GUARD_ALLOW_INIT_TRACKED_SYMLINK=1  allow creating `.helix/languages.toml`

cmd="${1:-apply}"

project_dir="${PWD}"

fail() {
	echo "$1" >&2
	exit 1
}

ensure_project_helix_dir() {
	mkdir -p "$project_dir/.helix"
}

ensure_tracked_languages_symlink() {
	local p="$project_dir/.helix/languages.toml"

	if [[ ! -e "$p" ]]; then
		if [[ "${HELIX_GUARD_ALLOW_INIT_TRACKED_SYMLINK:-}" == "1" ]]; then
			(cd "$project_dir/.helix" && ln -s languages.store.toml languages.toml)
		else
			fail "missing .helix/languages.toml (expected tracked symlink)"
		fi
	fi

	if [[ -e "$p" && ! -L "$p" ]]; then
		fail ".helix/languages.toml must be a symlink (tracked)"
	fi

	local target
	target="$(readlink "$p")"
	if [[ "$target" != "languages.store.toml" && "$target" != "./languages.store.toml" ]]; then
		fail ".helix/languages.toml must point to languages.store.toml (got: $target)"
	fi
}

update_store_symlink() {
	local store_languages_toml="${HELIX_GUARD_STORE_LANGUAGES_TOML:-}"
	[[ -n "$store_languages_toml" ]] || fail "missing HELIX_GUARD_STORE_LANGUAGES_TOML"

	local p="$project_dir/.helix/languages.store.toml"

	if [[ -e "$p" && ! -L "$p" ]]; then
		fail ".helix/languages.store.toml must be a symlink (ignored)"
	fi

	rm -f "$p"
	ln -s "$store_languages_toml" "$p"
}

check_xdg_no_store_direct() {
	local xdg_config_home="${HELIX_GUARD_XDG_CONFIG_HOME:-${XDG_CONFIG_HOME:-}}"
	[[ -n "$xdg_config_home" ]] || fail "missing XDG_CONFIG_HOME (or HELIX_GUARD_XDG_CONFIG_HOME)"

	local p="$xdg_config_home/helix/languages.toml"

	# Nothing to check if absent.
	if [[ ! -e "$p" ]]; then
		return 0
	fi

	if [[ -e "$p" && ! -L "$p" ]]; then
		fail "forbidden: XDG languages.toml must be a symlink"
	fi

	local target
	target="$(readlink "$p")"
	if [[ "$target" == /nix/store/* ]]; then
		fail "forbidden: XDG languages.toml must not point directly to nix store: $target"
	fi
}

ensure_xdg_references_project() {
	local xdg_config_home="${HELIX_GUARD_XDG_CONFIG_HOME:-${XDG_CONFIG_HOME:-}}"
	[[ -n "$xdg_config_home" ]] || return 0

	mkdir -p "$xdg_config_home/helix"

	# Pre-check: don't allow existing store-direct link.
	check_xdg_no_store_direct

	local p="$xdg_config_home/helix/languages.toml"
	rm -f "$p"
	ln -s "$project_dir/.helix/languages.toml" "$p"

	# Post-check: ensure we didn't accidentally create a store-direct link.
	check_xdg_no_store_direct
}

case "$cmd" in
apply)
	ensure_project_helix_dir
	ensure_tracked_languages_symlink
	update_store_symlink
	ensure_xdg_references_project
	;;
check-xdg)
	check_xdg_no_store_direct
	;;
*)
	fail "unknown command: $cmd"
	;;
esac
