{ ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      pythonTooling = pkgs.symlinkJoin {
        name = "python-tooling";
        paths = [
          pkgs.uv
          pkgs.ruff
          pkgs.pyright
          pkgs.ty
        ];
      };
    in
    {
      packages.python-tooling = pythonTooling;
      packages.python-lsp = pkgs.pyright;
      packages.python-lint = pkgs.ruff;
      packages.python-fmt = pkgs.ruff;

      devShells.python = pkgs.mkShell {
        packages = [ pythonTooling ];

        UV_PYTHON_PREFERENCE = "only-system";
        UV_PYTHON_DOWNLOADS = "never";
      };

      checks.python-smoke = pkgs.runCommand "python-smoke" { nativeBuildInputs = [ pythonTooling ]; } ''
        set -euo pipefail

        uv --version >/dev/null
        ruff --version >/dev/null
        pyright --version >/dev/null
        ty --version >/dev/null

        touch "$out"
      '';
    };
}
