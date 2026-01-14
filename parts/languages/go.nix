{ ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      goTooling = pkgs.symlinkJoin {
        name = "go-tooling";
        paths = [
          pkgs.go
          pkgs.gopls
          pkgs.golangci-lint
        ];
      };
    in
    {
      packages.go-tooling = goTooling;
      packages.go-lsp = pkgs.gopls;
      packages.go-lint = pkgs.golangci-lint;
      packages.go-fmt = pkgs.go;

      devShells.go = pkgs.mkShell {
        packages = [ goTooling ];
      };

      checks.go-smoke = pkgs.runCommand "go-smoke" { nativeBuildInputs = [ goTooling ]; } ''
        set -euo pipefail

        go version >/dev/null
        gopls version >/dev/null
        golangci-lint --version >/dev/null
        gofmt -h >/dev/null

        touch "$out"
      '';
    };
}
