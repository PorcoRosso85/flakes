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

      checks.forbid-xdg-store-direct-link =
        pkgs.runCommand "forbid-xdg-store-direct-link"
          {
            nativeBuildInputs = [
              pkgs.bash
              pkgs.coreutils
            ];
          }
          ''
            set -euo pipefail

            export HOME="$TMPDIR/helix-home"
            export XDG_CONFIG_HOME="$HOME/.config"
            mkdir -p "$XDG_CONFIG_HOME/helix"

            ln -s ${config.helix.languagesToml} "$XDG_CONFIG_HOME/helix/languages.toml"

            if ${pkgs.bash}/bin/bash ${./guards/helix-guard.sh} check-xdg; then
              echo "expected store-direct XDG link to be rejected" >&2
              exit 1
            fi

            touch "$out"
          '';

      checks.helix-guard-dry =
        pkgs.runCommand "helix-guard-dry"
          {
            nativeBuildInputs = [
              pkgs.bash
              pkgs.coreutils
              pkgs.ripgrep
            ];
          }
          ''
            set -euo pipefail

            files=(
              ${./devshell.nix}
              ${./checks.nix}
              ${./tests/forbid-xdg-store-direct-link.sh}
            )

            # Must call the shared guard implementation.
            rg -n "helix-guard\\.sh" "''${files[@]}" >/dev/null

            # Must not duplicate guard logic/messages outside the guard.
            if rg -n "\\.helix/languages\\.toml must be a symlink|missing \\.helix/languages\\.toml|readlink \\.helix" "''${files[@]}"; then
              echo "guard DRY violation: guard logic found outside guards/helix-guard.sh" >&2
              exit 1
            fi

            touch "$out"
          '';

    };
}
