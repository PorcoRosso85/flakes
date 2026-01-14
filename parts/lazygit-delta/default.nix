{ ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      mkLazygitDelta = import ./module.nix;
      mod = mkLazygitDelta { inherit pkgs; };

      mkChecks = import ./checks.nix;
    in
    {
      packages.lazygit = mod.package;

      checks = mkChecks {
        inherit pkgs;
        package = mod.package;
        cfgFile = mod.cfgFile;
      };
    };

  flake.lib.mkLazygitDelta = import ./module.nix;
}
