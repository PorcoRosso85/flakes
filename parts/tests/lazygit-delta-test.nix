{ ... }:
{
  perSystem =
    { pkgs, config, ... }:
    let
      test = pkgs.writeShellApplication {
        name = "test-lazygit-delta";
        runtimeInputs = [
          config.packages.git-tools
          pkgs.coreutils
          pkgs.ripgrep
          pkgs.util-linux
        ];
        text = ''
          set -euo pipefail

          export DELTA_BIN="${pkgs.delta}/bin/delta"

          exec ${pkgs.bash}/bin/bash ${./lazygit-delta-test.sh} "$PWD"
        '';
      };
    in
    {
      apps.test-lazygit-delta = {
        type = "app";
        program = "${test}/bin/test-lazygit-delta";
        meta.description = "Contract test for lazygit + delta side-by-side";
      };

      checks.test-lazygit-delta = test;
    };
}
