# Helix devShell
#
# Provides `devShells.helix` and a `hx` wrapper that:
# - runs anywhere (no `$PWD/.helix` dependency)
# - isolates HOME/XDG_* into TMPDIR (no user config/caches)
# - injects store-generated `languages.toml` into `$XDG_CONFIG_HOME/helix/languages.toml`
{ lib, ... }:
{
  perSystem =
    { pkgs, config, ... }:
    let
      hx = pkgs.writeShellScriptBin "hx" ''
        set -euo pipefail

        export TMPDIR=''${TMPDIR:-/tmp}
        export HOME="$TMPDIR/helix-home"
        export XDG_CONFIG_HOME="$HOME/.config"
        export XDG_CACHE_HOME="$HOME/.cache"
        export XDG_STATE_HOME="$HOME/.local/state"

        "${pkgs.coreutils}/bin/mkdir" -p "$XDG_CONFIG_HOME/helix" "$XDG_CACHE_HOME" "$XDG_STATE_HOME"

        "${pkgs.coreutils}/bin/rm" -f "$XDG_CONFIG_HOME/helix/languages.toml"
        "${pkgs.coreutils}/bin/ln" -s "${config.helix.languagesToml}" "$XDG_CONFIG_HOME/helix/languages.toml"

        exec "${pkgs.helix}/bin/hx" "$@"
      '';
    in
    {
      devShells.helix = pkgs.mkShell {
        packages = lib.unique ([ hx ] ++ config.helix.tools);

        # Keep interactive `nix develop .#helix` isolated as well.
        shellHook = ''
          set -euo pipefail

          export TMPDIR=''${TMPDIR:-/tmp}
          export HOME="$TMPDIR/helix-home"
          export XDG_CONFIG_HOME="$HOME/.config"
          export XDG_CACHE_HOME="$HOME/.cache"
          export XDG_STATE_HOME="$HOME/.local/state"

          "${pkgs.coreutils}/bin/mkdir" -p "$XDG_CONFIG_HOME/helix" "$XDG_CACHE_HOME" "$XDG_STATE_HOME"

          "${pkgs.coreutils}/bin/rm" -f "$XDG_CONFIG_HOME/helix/languages.toml"
          "${pkgs.coreutils}/bin/ln" -s "${config.helix.languagesToml}" "$XDG_CONFIG_HOME/helix/languages.toml"
        '';
      };
    };
}
