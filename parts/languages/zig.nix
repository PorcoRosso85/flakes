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
      packages.zig-lint = zigLint;
      packages.zig-fmt = zigFmt;

      devShells.zig = pkgs.mkShell {
        packages = [ zigTooling ];
      };

      checks.zig-smoke = pkgs.runCommand "zig-smoke" { nativeBuildInputs = [ zigTooling ]; } ''
        set -euo pipefail

        zig version >/dev/null
        zls --version >/dev/null
        zig fmt --help >/dev/null

        touch "$out"
      '';
    };
}
