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
      packages.python-diagnostics = pkgs.ruff;
      packages.python-fmt = pkgs.ruff;

      helix.tools = [ pythonTooling ];
      helix.languageServers.pyright = {
        command = "pyright-langserver";
        args = [ "--stdio" ];
      };
      helix.languages.python = {
        languageServers = [ "pyright" ];
        formatter = {
          command = "ruff";
          args = [
            "format"
            "-"
          ];
        };
      };

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
