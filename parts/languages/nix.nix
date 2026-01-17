{ ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      nixTooling = pkgs.symlinkJoin {
        name = "nix-tooling";
        paths = [
          pkgs.nix
          pkgs.nixd
          pkgs.nixfmt-rfc-style
          pkgs.statix
        ];
      };
    in
    {
      formatter = pkgs.nixfmt-rfc-style;

      packages.nix-tooling = nixTooling;
      packages.nix-lsp = pkgs.nixd;
      packages.nix-diagnostics = pkgs.statix;
      packages.nix-fmt = pkgs.nixfmt-rfc-style;

      helix.tools = [ nixTooling ];
      helix.languageServers.nixd = {
        command = "nixd";
        args = [ ];
      };
      helix.languages.nix = {
        languageServers = [ "nixd" ];
        formatter = {
          command = "nixfmt";
          args = [ ];
        };
      };

      devShells.nix = pkgs.mkShell {
        packages = [ nixTooling ];
      };

      checks.nix-smoke = pkgs.runCommand "nix-smoke" { nativeBuildInputs = [ nixTooling ]; } ''
        set -euo pipefail

        nix --version >/dev/null
        nixd --version >/dev/null
        statix --version >/dev/null
        nixfmt --version >/dev/null 2>&1 || nixfmt --help >/dev/null

        touch "$out"
      '';
    };
}
