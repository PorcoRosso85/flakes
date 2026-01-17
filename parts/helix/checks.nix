# Helix checks
{ lib, ... }:
{
  perSystem =
    { pkgs, config, ... }:
    let
      cmds = lib.unique (
        (lib.mapAttrsToList (_: s: s.command) config.helix.languageServers)
        ++ (lib.concatMap (l: if l.formatter == null then [ ] else [ l.formatter.command ]) (
          lib.mapAttrsToList (_: v: v) config.helix.languages
        ))
      );

      cmdArgs = lib.concatStringsSep " " (map lib.escapeShellArg cmds);

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

            ln -s ${config.helix.languagesToml} "$XDG_CONFIG_HOME/helix/languages.toml"

            # Run without category for stability.
            TERM=dumb NO_COLOR=1 hx --health 2>&1 | ${pkgs.bash}/bin/bash ${./tests/hx-health-contract.sh} ${cmdArgs}

            touch "$out"
          '';
    in
    {
      checks.helix-commands-on-path = helixCommandsOnPath;
      checks.hx-health-output-contract = hxHealthContract;
    };
}
