{ ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      test = pkgs.writeShellApplication {
        name = "test";
        runtimeInputs = [ pkgs.nix ];
        text = ''
          set -euo pipefail
          nix flake check -L
        '';
      };
    in
    {
      apps.test = {
        type = "app";
        program = "${test}/bin/test";
        meta.description = "Run sync flake checks";
      };
    };
}
