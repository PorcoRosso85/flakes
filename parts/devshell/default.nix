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

        # Deterministic defaults; users can override explicitly.
        : "''${OPENCODE_DISABLE_LSP_DOWNLOAD:=true}"
        : "''${OPENCODE_DISABLE_AUTOUPDATE:=true}"
        export OPENCODE_DISABLE_LSP_DOWNLOAD OPENCODE_DISABLE_AUTOUPDATE

        exec "${pkgs.opencode}/bin/opencode" "$@"
      '';

      # Avoid lazygit trying to migrate a store config file.
      # We pass the pager directly via environment variables.

      lazygit = pkgs.writeShellScriptBin "lazygit" ''
        set -euo pipefail

        # If the user explicitly provides config flags, don't override them.
        for arg in "$@"; do
          case "$arg" in
            -ucf|--use-config-file|-ucd|--use-config-dir)
              exec "${pkgs.lazygit}/bin/lazygit" "$@"
              ;;
          esac
        done

        export DELTA_FEATURES=+side-by-side
        export GIT_PAGER="${pkgs.delta}/bin/delta --paging=never"
        exec "${pkgs.lazygit}/bin/lazygit" "$@"
      '';

      gitTools = pkgs.symlinkJoin {
        name = "git-tools";
        paths = [
          pkgs.git
          pkgs.gh
          lazygit
          pkgs.delta
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
    };
}
