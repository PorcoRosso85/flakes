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
      packages.go-diagnostics = pkgs.golangci-lint;
      packages.go-fmt = pkgs.go;

      helix.tools = [ goTooling ];
      helix.languageServers.gopls = {
        command = "gopls";
        args = [ ];
      };
      helix.languages.go = {
        languageServers = [ "gopls" ];
        formatter = {
          command = "gofmt";
          args = [ ];
        };
      };

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
