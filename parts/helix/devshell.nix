# Helix devShell
#
# Provides `devShells.helix` and keeps the repo git-clean by using:
#   .helix/languages.toml        (tracked) -> languages.store.toml
#   .helix/languages.store.toml  (ignored) -> /nix/store/.../helix-languages.toml
{ lib, ... }:
{
  perSystem =
    { pkgs, config, ... }:
    let
      hx = pkgs.writeShellScriptBin "hx" ''
        set -euo pipefail

        # XDG/HOME isolation (Helix only): keep real $HOME untouched.
        export TMPDIR=''${TMPDIR:-/tmp}
        export HOME="$TMPDIR/helix-home"
        export XDG_CONFIG_HOME="$HOME/.config"
        export XDG_CACHE_HOME="$HOME/.cache"
        export XDG_STATE_HOME="$HOME/.local/state"

        "${pkgs.coreutils}/bin/mkdir" -p "$XDG_CONFIG_HOME/helix" "$XDG_CACHE_HOME" "$XDG_STATE_HOME"

        "${pkgs.coreutils}/bin/mkdir" -p .helix

        if [[ -e .helix/languages.toml && ! -L .helix/languages.toml ]]; then
          echo ".helix/languages.toml must be a symlink (tracked)" >&2
          exit 1
        fi

        if [[ ! -L .helix/languages.toml ]]; then
          echo "missing .helix/languages.toml (expected tracked symlink)" >&2
          exit 1
        fi

        target="$("${pkgs.coreutils}/bin/readlink" .helix/languages.toml)"
        if [[ "$target" != "languages.store.toml" && "$target" != "./languages.store.toml" ]]; then
          echo ".helix/languages.toml must point to languages.store.toml (got: $target)" >&2
          exit 1
        fi

        if [[ -e .helix/languages.store.toml && ! -L .helix/languages.store.toml ]]; then
          echo ".helix/languages.store.toml must be a symlink (ignored)" >&2
          exit 1
        fi

        "${pkgs.coreutils}/bin/rm" -f .helix/languages.store.toml
        "${pkgs.coreutils}/bin/ln" -s "${config.helix.languagesToml}" .helix/languages.store.toml

        # Guard: forbid XDG languages.toml -> /nix/store/*
        "${pkgs.bash}/bin/bash" ${./tests/forbid-xdg-store-direct-link.sh}

        "${pkgs.coreutils}/bin/rm" -f "$XDG_CONFIG_HOME/helix/languages.toml"
        "${pkgs.coreutils}/bin/ln" -s "$PWD/.helix/languages.toml" "$XDG_CONFIG_HOME/helix/languages.toml"

        # Guard again after linking.
        "${pkgs.bash}/bin/bash" ${./tests/forbid-xdg-store-direct-link.sh}

        exec "${pkgs.helix}/bin/hx" "$@"
      '';
    in
    {
      devShells.helix = pkgs.mkShell {
        packages = lib.unique ([ hx ] ++ config.helix.tools);

        shellHook = ''
          set -euo pipefail

          "${pkgs.coreutils}/bin/mkdir" -p .helix

          if [[ -e .helix/languages.toml && ! -L .helix/languages.toml ]]; then
            echo ".helix/languages.toml must be a symlink (tracked)" >&2
            exit 1
          fi

          if [[ ! -L .helix/languages.toml ]]; then
            echo "missing .helix/languages.toml (expected tracked symlink)" >&2
            exit 1
          fi

          target="$("${pkgs.coreutils}/bin/readlink" .helix/languages.toml)"
          if [[ "$target" != "languages.store.toml" && "$target" != "./languages.store.toml" ]]; then
            echo ".helix/languages.toml must point to languages.store.toml (got: $target)" >&2
            exit 1
          fi

          if [[ -e .helix/languages.store.toml && ! -L .helix/languages.store.toml ]]; then
            echo ".helix/languages.store.toml must be a symlink (ignored)" >&2
            exit 1
          fi

          "${pkgs.coreutils}/bin/rm" -f .helix/languages.store.toml
          "${pkgs.coreutils}/bin/ln" -s "${config.helix.languagesToml}" .helix/languages.store.toml
        '';
      };
    };
}
