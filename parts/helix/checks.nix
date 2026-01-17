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

      hxHealthContract =
        pkgs.runCommand "hx-health-output-contract"
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

                        mkdir -p .helix
                        ln -s languages.store.toml .helix/languages.toml
                        ln -s ${config.helix.languagesToml} .helix/languages.store.toml

                        ln -s "$PWD/.helix/languages.toml" "$XDG_CONFIG_HOME/helix/languages.toml"

            # Guard: forbid XDG languages.toml -> /nix/store/*
            ${pkgs.bash}/bin/bash ${./tests/forbid-xdg-store-direct-link.sh}

            export HELIX_REQUIRED_COMMANDS_FILE="${requiredCommandsFile}"


                        # Run without category for stability.
                        TERM=dumb NO_COLOR=1 hx --health 2>&1 | ${pkgs.bash}/bin/bash ${./tests/hx-health-contract.sh}

                        touch "$out"
          '';
    in
    {
      checks.helix-commands-on-path = helixCommandsOnPath;
      checks.hx-health-output-contract = hxHealthContract;

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

            if ${pkgs.bash}/bin/bash ${./tests/forbid-xdg-store-direct-link.sh}; then
              echo "expected store-direct XDG link to be rejected" >&2
              exit 1
            fi

            touch "$out"
          '';
    };
}
