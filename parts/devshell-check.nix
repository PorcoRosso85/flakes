{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      sys = pkgs.system;
      oc = inputs.opencode;

      hasOpencodePkg =
        oc ? packages.${sys} && (oc.packages.${sys} ? opencode || oc.packages.${sys} ? default);
      hasOpencodeApp = oc ? apps.${sys} && (oc.apps.${sys} ? opencode || oc.apps.${sys} ? opencode-dev);

      opencodePkg =
        if hasOpencodePkg then
          oc.packages.${sys}.opencode or oc.packages.${sys}.default
        else if hasOpencodeApp then
          pkgs.writeShellApplication {
            name = "opencode";
            text = ''exec ${oc.apps.${sys}.opencode or oc.apps.${sys}.opencode-dev.program} "$@"'';
          }
        else
          throw "inputs.opencode must expose packages.${sys}.opencode/default or apps.${sys}.opencode/opencode-dev";

      opencodeConfig = ../opencode.json;
    in
    {
      checks.opencode-smoke = pkgs.runCommand "opencode-smoke" { nativeBuildInputs = [ opencodePkg ]; } ''
        set -euo pipefail

        export HOME="$TMPDIR"
        export XDG_CACHE_HOME="$TMPDIR/.cache"
        export XDG_CONFIG_HOME="$TMPDIR/.config"
        mkdir -p "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME"

        test -f ${opencodeConfig}
        ${opencodePkg}/bin/opencode --help >/dev/null
        touch $out
      '';
    };
}
