{ ... }:
{
  perSystem =
    { pkgs, config, ... }:
    let
      integration = pkgs.writeShellApplication {
        name = "test-integration";
        runtimeInputs = [
          config.packages.editor-tools
          pkgs.coreutils
        ];
        text = ''
          set -euo pipefail

          tmp="$(mktemp -d "''${TMPDIR:-/tmp}/flakes-test.integration.XXXXXX")"
          export TMPDIR="$tmp"

          hx --version >/dev/null

          # Keep opencode tests isolated from user HOME.
          export HOME="$tmp/opencode-home"
          mkdir -p "$HOME"

          opencode --version >/dev/null
          opencode --help >/dev/null

          test -L "$tmp/helix-home/.config/helix/languages.toml"

          echo "ok"
        '';
      };

      e2e = pkgs.writeShellApplication {
        name = "test-e2e";
        runtimeInputs = [
          config.packages.editor-tools
          pkgs.coreutils
        ];
        text = ''
          set -euo pipefail

          tmp="$(mktemp -d "''${TMPDIR:-/tmp}/flakes-test.e2e.XXXXXX")"
          export TMPDIR="$tmp"

          # If wrappers don't override HOME/XDG, these would be touched.
          export HOME="$tmp/trap-home"
          mkdir -p "$HOME"
          test ! -e "$HOME/.config"

          hx --version >/dev/null

          # Keep opencode tests isolated from user HOME.
          export HOME="$tmp/opencode-home"
          mkdir -p "$HOME"

          opencode --version >/dev/null

          test -L "$tmp/helix-home/.config/helix/languages.toml"

          test ! -e "$tmp/trap-home/.config"

          echo "ok"
        '';
      };
    in
    {
      apps.test-integration = {
        type = "app";
        program = "${integration}/bin/test-integration";
        meta.description = "Integration smoke for #edit wrappers";
      };

      apps.test-e2e = {
        type = "app";
        program = "${e2e}/bin/test-e2e";
        meta.description = "E2E isolation smoke for #edit wrappers";
      };
    };
}
