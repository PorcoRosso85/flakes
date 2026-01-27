{ ... }:
{
  flake.nixosModules.default = import ../nixosModules/syncthing-receiver.nix;
}
