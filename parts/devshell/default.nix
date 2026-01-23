{ ... }:
{
  perSystem =
    { pkgs, config, ... }:
    let
      hx = pkgs.writeShellScriptBin "hx" ''
        set -euo pipefail

        export TMPDIR=''${TMPDIR:-/tmp}

        # Isolation: do not read user ~/.config
        export HOME="$TMPDIR/helix-home"
        export XDG_CONFIG_HOME="$HOME/.config"
        export XDG_CACHE_HOME="$HOME/.cache"
        export XDG_STATE_HOME="$HOME/.local/state"

        "${pkgs.coreutils}/bin/mkdir" -p "$XDG_CONFIG_HOME/helix" "$XDG_CACHE_HOME" "$XDG_STATE_HOME"

        "${pkgs.coreutils}/bin/rm" -f "$XDG_CONFIG_HOME/helix/languages.toml"
        "${pkgs.coreutils}/bin/ln" -s "${config.helix.languagesToml}" "$XDG_CONFIG_HOME/helix/languages.toml"

        exec "${pkgs.helix}/bin/hx" "$@"
      '';

      opencodeConfig = ../../opencode.json;

      opencode = pkgs.writeShellScriptBin "opencode" ''
        set -euo pipefail

        export OPENCODE_CONFIG="${opencodeConfig}"
        exec "${pkgs.opencode}/bin/opencode" "$@"
      '';

      gitTools = pkgs.symlinkJoin {
        name = "git-tools";
        paths = [
          pkgs.git
          pkgs.gh
          pkgs.lazygit
        ];
      };

      editorTools = pkgs.symlinkJoin {
        name = "editor-tools";
        paths = [
          hx
          opencode
        ];
      };
    in
    {
      packages.git-tools = gitTools;
      packages.editor-tools = editorTools;

      devShells.default = pkgs.mkShell {
        packages = [ gitTools ];
      };

      devShells.edit = pkgs.mkShell {
        packages = [ editorTools ];
      };
    };
}
