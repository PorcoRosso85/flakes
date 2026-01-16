# Helix devShell
#
# Provides `devShells.helix` and keeps the repo git-clean by using:
#   .helix/languages.toml        (tracked) -> languages.store.toml
#   .helix/languages.store.toml  (ignored) -> /nix/store/.../helix-languages.toml
{ lib, ... }:
{
  perSystem =
    { pkgs, config, ... }:
    {
      devShells.helix = pkgs.mkShell {
        packages = lib.unique ([ pkgs.helix ] ++ config.helix.tools);

        shellHook = ''
          set -euo pipefail

          # XDG/HOME isolation (Helix only): keep real $HOME untouched.
          export HOME="$TMPDIR/helix-home"
          export XDG_CONFIG_HOME="$HOME/.config"
          export XDG_CACHE_HOME="$HOME/.cache"
          export XDG_STATE_HOME="$HOME/.local/state"
          mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME"

          mkdir -p .helix

          if [[ -e .helix/languages.toml && ! -L .helix/languages.toml ]]; then
            echo ".helix/languages.toml must be a symlink (tracked)" >&2
            exit 1
          fi

          if [[ ! -L .helix/languages.toml ]]; then
            echo "missing .helix/languages.toml (expected tracked symlink)" >&2
            exit 1
          fi

          target="$(readlink .helix/languages.toml)"
          if [[ "$target" != "languages.store.toml" && "$target" != "./languages.store.toml" ]]; then
            echo ".helix/languages.toml must point to languages.store.toml (got: $target)" >&2
            exit 1
          fi

          if [[ -e .helix/languages.store.toml && ! -L .helix/languages.store.toml ]]; then
            echo ".helix/languages.store.toml must be a symlink (ignored)" >&2
            exit 1
          fi

          rm -f .helix/languages.store.toml
          ln -s "${config.helix.languagesToml}" .helix/languages.store.toml
        '';
      };
    };
}
