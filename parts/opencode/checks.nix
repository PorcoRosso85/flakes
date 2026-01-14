{ inputs, ... }:
{
  perSystem =
    { pkgs, config, ... }:
    let
      opencodePkg =
        let
          sys = pkgs.system;
          oc = inputs.opencode;

          hasOpencodePkg =
            oc ? packages.${sys} && (oc.packages.${sys} ? opencode || oc.packages.${sys} ? default);
          hasOpencodeApp = oc ? apps.${sys} && (oc.apps.${sys} ? opencode || oc.apps.${sys} ? opencode-dev);
        in
        if hasOpencodePkg then
          oc.packages.${sys}.opencode or oc.packages.${sys}.default
        else if hasOpencodeApp then
          pkgs.writeShellApplication {
            name = "opencode";
            text = ''exec ${oc.apps.${sys}.opencode or oc.apps.${sys}.opencode-dev.program} "$@"'';
          }
        else
          throw "inputs.opencode must expose packages.${sys}.opencode/default or apps.${sys}.opencode/opencode-dev";

      lspCheckEnv = ''
        set -euo pipefail

        export HOME="$TMPDIR/home"
        export XDG_CONFIG_HOME="$TMPDIR/cfg"
        export XDG_CACHE_HOME="$TMPDIR/cache"
        mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"

        # Always run outside git/project tree (avoid project config/.opencode merge)
        cd "$TMPDIR"

        export OPENCODE_CONFIG="${./config/opencode-lsp.json}"
        # Last precedence override (blocks plugin/provider/etc from project/global configs)
        export OPENCODE_CONFIG_CONTENT='{"$schema":"https://opencode.ai/config.json","plugin":[]}'

        export OPENCODE_OUTPUT_CONTRACT="${./tests/output-contract.sh}"

        export OPENCODE_LSP_SMOKE_RETRIES="${toString 15}"
        export OPENCODE_LSP_SMOKE_SLEEP_S="${toString 0.4}"
      '';

      bunSmoke =
        pkgs.runCommand "opencode-bun-lsp-smoke"
          {
            nativeBuildInputs = [
              opencodePkg
              pkgs.bash
              pkgs.coreutils
              pkgs.gnugrep
              pkgs.jq
              config.packages.bun-lsp
              pkgs.typescript
            ];
          }
          ''
            ${lspCheckEnv}
            bash ${./tests/bun-lsp-smoke.sh}
            touch "$out"
          '';

      pythonSmoke =
        pkgs.runCommand "opencode-python-lsp-smoke"
          {
            nativeBuildInputs = [
              opencodePkg
              pkgs.bash
              pkgs.coreutils
              pkgs.gnugrep
              pkgs.jq
              config.packages.python-lsp
            ];
          }
          ''
            ${lspCheckEnv}
            bash ${./tests/python-lsp-smoke.sh}
            touch "$out"
          '';
    in
    {
      checks.opencode-bun-lsp-smoke = bunSmoke;
      checks.opencode-python-lsp-smoke = pythonSmoke;
    };
}
