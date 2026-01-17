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

        export HELIX_GUARD_STORE_LANGUAGES_TOML="${config.helix.languagesToml}"
        export HELIX_GUARD_XDG_CONFIG_HOME="$XDG_CONFIG_HOME"

        "${pkgs.bash}/bin/bash" ${./guards/helix-guard.sh} apply

        exec "${pkgs.helix}/bin/hx" "$@"
      '';
    in
    {
      devShells.helix = pkgs.mkShell {
        packages = lib.unique ([ hx ] ++ config.helix.tools);

        shellHook = ''
            set -euo pipefail

            export HELIX_GUARD_STORE_LANGUAGES_TOML="${config.helix.languagesToml}"

          export PATH="${pkgs.coreutils}/bin:${pkgs.bash}/bin:$PATH"

          export PATH="${pkgs.coreutils}/bin:${pkgs.bash}/bin:$PATH"

          "${pkgs.bash}/bin/bash" ${./guards/helix-guard.sh} apply

        '';
      };
    };
}
