{ ... }:
{
  perSystem =
    { pkgs, config, ... }:
    let
      opencodeConfig = ../../opencode.json;

      configVanilla =
        pkgs.runCommand "opencode-config-vanilla"
          {
            nativeBuildInputs = [
              pkgs.jq
              pkgs.coreutils
            ];
          }
          ''
            set -euo pipefail

            ${pkgs.jq}/bin/jq -e 'keys == ["$schema"]' "${opencodeConfig}" >/dev/null

            touch "$out"
          '';

      opencodeSmoke =
        pkgs.runCommand "opencode-smoke"
          {
            nativeBuildInputs = [
              pkgs.opencode
              pkgs.coreutils
            ];
          }
          ''
            set -euo pipefail

            export HOME="$TMPDIR/home"
            export XDG_CONFIG_HOME="$HOME/.config"
            export XDG_CACHE_HOME="$HOME/.cache"
            export XDG_STATE_HOME="$HOME/.local/state"
            mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME"

            # Avoid project config merge and exercise repo config.
            cd "$TMPDIR"
            export OPENCODE_CONFIG="${opencodeConfig}"

            opencode --version >/dev/null
            opencode --help >/dev/null

            touch "$out"
          '';

      opencodeWrapperIsolated =
        pkgs.runCommand "opencode-wrapper-isolated"
          {
            nativeBuildInputs = [
              config.packages.editor-tools
              pkgs.coreutils
            ];
          }
          ''
            set -euo pipefail

            tmp="$TMPDIR/opencode-wrapper"
            mkdir -p "$tmp"

            export TMPDIR="$tmp"

            export HOME="$PWD/trap-home"
            mkdir -p "$HOME"
            test ! -e "$HOME/.config"

            opencode --version >/dev/null

            test -d "$tmp/opencode-home/.config/opencode"
            test ! -e "$HOME/.config"

            touch "$out"
          '';
    in
    {
      checks.opencode-config-vanilla = configVanilla;
      checks.opencode-smoke = opencodeSmoke;
      checks.opencode-wrapper-isolated = opencodeWrapperIsolated;
    };
}
