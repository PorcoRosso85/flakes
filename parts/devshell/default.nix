{ inputs, lib, ... }:
{
  perSystem =
    { pkgs, config, ... }:
    let
      sys = pkgs.system;
      oc = inputs.opencode;

      hasOpencodePkg =
        oc ? packages.${sys} && (oc.packages.${sys} ? opencode || oc.packages.${sys} ? default);
      hasOpencodeApp = oc ? apps.${sys} && (oc.apps.${sys} ? opencode || oc.apps.${sys} ? opencode-dev);

      opencodeUpstream =
        if hasOpencodePkg then
          oc.packages.${sys}.opencode or oc.packages.${sys}.default
        else if hasOpencodeApp then
          pkgs.writeShellApplication {
            name = "opencode";
            text = ''exec ${oc.apps.${sys}.opencode or oc.apps.${sys}.opencode-dev.program} "$@"'';
          }
        else
          throw "inputs.opencode must expose packages.${sys}.opencode/default or apps.${sys}.opencode/opencode-dev";

      opencodeConfig = ../../opencode.json;

      opencode = pkgs.writeShellApplication {
        name = "opencode";
        meta.mainProgram = "opencode";
        text = ''
          export OPENCODE_CONFIG="${opencodeConfig}"
          exec ${opencodeUpstream}/bin/opencode "$@"
        '';
      };

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
