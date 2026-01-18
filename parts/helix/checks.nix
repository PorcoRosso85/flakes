# Helix checks
{ lib, ... }:
{
  perSystem =
    { pkgs, config, ... }:
    let
      cmds = config.helix.commandsList;

      cmdArgs = lib.concatStringsSep " " (map lib.escapeShellArg cmds);

      requiredCommandsFile = pkgs.writeText "helix-required-commands.txt" (
        (lib.concatStringsSep "\n" cmds) + "\n"
      );

      helixCommandsOnPath =
        pkgs.runCommand "helix-commands-on-path"
          {
            nativeBuildInputs = lib.unique (
              config.helix.tools
              ++ [
                pkgs.bash
                pkgs.coreutils
              ]
            );
          }
          ''
            set -euo pipefail
            ${pkgs.bash}/bin/bash ${./tests/commands-on-path.sh} ${cmdArgs}
            touch "$out"
          '';

      hxHealthAnywhere =
        pkgs.runCommand "hx-health-anywhere"
          {
            nativeBuildInputs = lib.unique (
              config.helix.tools
              ++ [
                pkgs.helix
                pkgs.bash
                pkgs.coreutils
                pkgs.gnused
              ]
            );
          }
          ''
            set -euo pipefail

            export HOME="$TMPDIR/helix-home"
            export XDG_CONFIG_HOME="$HOME/.config"
            export XDG_CACHE_HOME="$HOME/.cache"
            export XDG_STATE_HOME="$HOME/.local/state"
            mkdir -p "$XDG_CONFIG_HOME/helix" "$XDG_CACHE_HOME" "$XDG_STATE_HOME"

            rm -f "$XDG_CONFIG_HOME/helix/languages.toml"
            ln -s ${config.helix.languagesToml} "$XDG_CONFIG_HOME/helix/languages.toml"

            export HELIX_REQUIRED_COMMANDS_FILE="${requiredCommandsFile}"

            # Run without category for stability.
            TERM=dumb NO_COLOR=1 hx --health 2>&1 | ${pkgs.bash}/bin/bash ${./tests/hx-health-contract.sh}

            touch "$out"
          '';
    in
    {
      checks.helix-commands-on-path = helixCommandsOnPath;
      checks.hx-health-anywhere = hxHealthAnywhere;

    };
}
