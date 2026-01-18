{ ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      rustAnalyzer = pkgs.rust-analyzer;
      rustTooling = pkgs.symlinkJoin {
        name = "rust-tooling";
        paths = [
          pkgs.rustc
          pkgs.cargo
          rustAnalyzer
          pkgs.rustfmt
          pkgs.clippy
        ];
      };

      smoke = pkgs.runCommand "rust-smoke" { nativeBuildInputs = [ rustTooling ]; } ''
        set -euo pipefail

        missing=0

        need() {
          if ! command -v "$1" >/dev/null 2>&1; then
            echo "missing: $1" >&2
            missing=1
            return 0
          fi
          "$1" --version >/dev/null 2>&1 || true
        }

        need rustc
        need cargo
        need rust-analyzer
        need rustfmt
        need cargo-clippy

        test "$missing" -eq 0
        mkdir -p "$out"
        echo "ok" > "$out/result"
      '';
    in
    {
      packages.rust-tooling = rustTooling;
      packages.rust-lsp = rustAnalyzer;
      packages.rust-diagnostics = pkgs.clippy;
      packages.rust-fmt = pkgs.rustfmt;

      helix.tools = [ rustTooling ];
      helix.languageServers."rust-analyzer" = {
        command = "rust-analyzer";
        args = [ ];
      };
      helix.languages.rust = {
        languageServers = [ "rust-analyzer" ];
        formatter = {
          command = "rustfmt";
          args = [
            "--emit"
            "stdout"
          ];
        };
      };

      checks.rust-smoke = smoke;
    };
}
