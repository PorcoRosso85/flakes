{ lib, ... }:
{
  # Stub module to force spec checks red first.
  options.syncReceiver.enable = lib.mkEnableOption "Syncthing receive-only folder for Windows host";
}
