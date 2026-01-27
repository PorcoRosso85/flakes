{
  config,
  lib,
  ...
}:

let
  cfg = config.syncReceiver;

  mkPathNotNestedAssertion =
    {
      name,
      child,
      parent,
    }:
    {
      assertion = child != parent && !(lib.hasPrefix "${parent}/" child);
      message = "${name} must not be inside the sync folder";
    };
in
{
  options.syncReceiver = {
    enable = lib.mkEnableOption "Syncthing receive-only folder for Windows host";

    folderId = lib.mkOption {
      type = lib.types.str;
      default = "win-sync";
      description = "Syncthing folder ID shared with Windows.";
    };

    folderPath = lib.mkOption {
      type = lib.types.str;
      default = "/home/nixos/.syncthing";
      description = "Path to the receive-only folder on NixOS.";
    };

    windowsDeviceName = lib.mkOption {
      type = lib.types.str;
      default = "windows";
      description = "Name used for the Windows device in Syncthing settings.";
    };

    windowsDeviceId = lib.mkOption {
      type = lib.types.str;
      example = "AAAAAAA-BBBBBBB-CCCCCCC-DDDDDDD-EEEEEEE-FFFFFFF-GGGGGGG-HHHHHHH";
      description = "Syncthing Device ID for the Windows host.";
    };

    syncthingUser = lib.mkOption {
      type = lib.types.str;
      default = "nixos";
      description = "User to run Syncthing as.";
    };

    syncthingGroup = lib.mkOption {
      type = lib.types.str;
      default = "users";
      description = "Group to run Syncthing as.";
    };

    configDir = lib.mkOption {
      type = lib.types.str;
      default = "/home/nixos/.config/syncthing";
      description = "Syncthing config directory (must be outside sync folder).";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/home/nixos/.local/share/syncthing";
      description = "Syncthing data/database directory (must be outside sync folder).";
    };

    versioningCleanoutDays = lib.mkOption {
      type = lib.types.int;
      default = 30;
      description = "Trashcan versioning cleanout days.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (mkPathNotNestedAssertion {
        name = "syncReceiver.configDir";
        child = cfg.configDir;
        parent = cfg.folderPath;
      })
      (mkPathNotNestedAssertion {
        name = "syncReceiver.dataDir";
        child = cfg.dataDir;
        parent = cfg.folderPath;
      })
    ];

    services.syncthing = {
      enable = true;
      user = cfg.syncthingUser;
      group = cfg.syncthingGroup;

      configDir = cfg.configDir;
      dataDir = cfg.dataDir;
      databaseDir = cfg.dataDir;

      openDefaultPorts = true;
      guiAddress = "127.0.0.1:8384";

      settings = {
        devices.${cfg.windowsDeviceName} = {
          id = cfg.windowsDeviceId;
        };

        folders.${cfg.folderId} = {
          id = cfg.folderId;
          path = cfg.folderPath;
          type = "receiveonly";
          devices = [ cfg.windowsDeviceName ];
          versioning = {
            type = "trashcan";
            params.cleanoutDays = toString cfg.versioningCleanoutDays;
          };
        };
      };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.folderPath} 0700 ${cfg.syncthingUser} ${cfg.syncthingGroup} -"
    ];
  };
}
