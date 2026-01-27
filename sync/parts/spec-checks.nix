{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      lib = pkgs.lib;

      eval = inputs.nixpkgs.lib.nixosSystem {
        system = pkgs.system;
        modules = [
          inputs.self.nixosModules.default
          (
            { ... }:
            {
              syncReceiver.enable = true;
              system.stateVersion = "25.05";
            }
          )
        ];
      };

      cfg = eval.config;

      specOk =
        assert lib.asserts.assertMsg cfg.services.syncthing.enable "services.syncthing.enable must be true";
        true;
    in
    {
      checks.sync-module-spec = builtins.seq specOk (
        pkgs.runCommand "sync-module-spec" { } ''
          touch $out
        ''
      );
    };
}
