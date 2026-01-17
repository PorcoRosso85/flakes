{ ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      zigTooling = pkgs.symlinkJoin {
        name = "zig-tooling";
        paths = [
          pkgs.zig
          pkgs.zls
        ];
      };

      zigFmt = pkgs.writeShellScriptBin "zig-fmt" ''
        exec zig fmt "$@"
      '';

      zigLint = pkgs.writeShellScriptBin "zig-lint" ''
        # YAGNI: start with fmt-as-lint (format check).
        exec zig fmt --check "$@"
      '';
    in
    {
      packages.zig-tooling = zigTooling;
      packages.zig-lsp = pkgs.zls;
      packages.zig-diagnostics = zigLint;
      packages.zig-lint = zigLint;
      packages.zig-fmt = zigFmt;

      helix.tools = [ zigTooling ];
      helix.languageServers.zls = {
        command = "zls";
        args = [ ];
      };
      helix.languages.zig = {
        languageServers = [ "zls" ];
        formatter = {
          command = "zig";
          args = [
            "fmt"
            "--stdin"
          ];
        };
      };

      devShells.zig = pkgs.mkShell {
        packages = [ zigTooling ];
      };

      checks.zig-smoke =
        pkgs.runCommand "zig-smoke"
          {
            nativeBuildInputs = [
              zigTooling
              zigFmt
              zigLint
            ];
          }
          ''
            set -euo pipefail

            zig version >/dev/null
            zls --version >/dev/null
            zig fmt --help >/dev/null

            tmp="$(mktemp -d)"
            printf 'const std = @import("std");\n' >"$tmp/main.zig"

            zig-fmt --check "$tmp/main.zig" >/dev/null
            zig-lint "$tmp/main.zig" >/dev/null

            touch "$out"
          '';
    };
}
