{ ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      bunTooling = pkgs.symlinkJoin {
        name = "bun-tooling";
        paths = [
          pkgs.bun
          pkgs.typescript
          pkgs.typescript-language-server
          pkgs.oxlint
          pkgs.oxfmt
        ];
      };
    in
    {
      packages.bun-tooling = bunTooling;
      packages.bun-lsp = pkgs.typescript-language-server;
      packages.bun-diagnostics = pkgs.oxlint;
      packages.bun-fmt = pkgs.oxfmt;

      helix.tools = [ bunTooling ];
      helix.languageServers."typescript-language-server" = {
        command = "typescript-language-server";
        args = [ "--stdio" ];
      };
      helix.languages.typescript = {
        languageServers = [ "typescript-language-server" ];
        formatter = {
          command = "oxfmt";
          args = [
            "--stdin-filepath"
            "%{buffer_name}"
          ];
        };
      };

      checks.bun-smoke = pkgs.runCommand "bun-smoke" { nativeBuildInputs = [ bunTooling ]; } ''
        set -euo pipefail

        bun --version >/dev/null
        tsc --version >/dev/null
        typescript-language-server --version >/dev/null
        oxlint --version >/dev/null
        oxfmt --version >/dev/null

        touch "$out"
      '';
    };
}
