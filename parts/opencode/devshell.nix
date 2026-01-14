{ inputs, ... }:
{
  perSystem =
    { pkgs, config, ... }:
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

      lspTooling = pkgs.symlinkJoin {
        name = "opencode-lsp-tooling";
        paths = [
          config.packages.bun-lsp
          pkgs.typescript
          config.packages.python-lsp
        ];
      };
    in
    {
      devShells.default = pkgs.mkShell {
        packages = [
          opencodePkg
          lspTooling
          config.packages.lazygit
        ];

        OPENCODE_CONFIG = "${opencodeConfig}";
      };
    };
}
