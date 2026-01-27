{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      lib = pkgs.lib;

      mkTestSystem =
        moduleOverrides:
        inputs.nixpkgs.lib.nixosSystem {
          system = pkgs.system;
          modules = [
            inputs.self.nixosModules.default
            (
              { ... }:
              {
                syncReceiver = {
                  enable = true;
                  folderId = "win-sync";
                  folderPath = "/home/nixos/.syncthing";
                  windowsDeviceId = "DUMMY-DEVICE-ID";
                };

                system.stateVersion = "25.05";
              }
            )
          ]
          ++ moduleOverrides;
        };

      assertSpec =
        cfg:
        let
          folderPath = "/home/nixos/.syncthing";
          folder = cfg.services.syncthing.settings.folders."win-sync";
          configDir = toString cfg.services.syncthing.configDir;
          dataDir = toString cfg.services.syncthing.dataDir;
        in
        assert lib.asserts.assertMsg cfg.services.syncthing.enable "syncthing must be enabled";
        assert lib.asserts.assertMsg (
          cfg.services.syncthing.user == "nixos"
        ) "syncthing must run as user nixos";
        assert lib.asserts.assertMsg (
          cfg.services.syncthing.group == "users"
        ) "syncthing must run as group users";
        assert lib.asserts.assertMsg (
          cfg.services.syncthing.guiAddress == "127.0.0.1:8384"
        ) "GUI must bind to 127.0.0.1:8384";
        assert lib.asserts.assertMsg cfg.services.syncthing.openDefaultPorts
          "Default sync ports must be opened";
        assert lib.asserts.assertMsg (
          folder.path == folderPath
        ) "Folder path must be /home/nixos/.syncthing";
        assert lib.asserts.assertMsg (folder.type == "receiveonly") "Folder must be receive-only";
        assert lib.asserts.assertMsg (folder.versioning.type == "trashcan") "Versioning must be trashcan";
        assert lib.asserts.assertMsg (
          configDir != folderPath && !(lib.hasPrefix "${folderPath}/" configDir)
        ) "configDir must not be inside the sync folder";
        assert lib.asserts.assertMsg (
          dataDir != folderPath && !(lib.hasPrefix "${folderPath}/" dataDir)
        ) "dataDir must not be inside the sync folder";
        true;

      goodEval = mkTestSystem [ ];

      badConfigDirEval = builtins.tryEval (mkTestSystem [
        (
          { ... }:
          {
            syncReceiver.configDir = "/home/nixos/.syncthing/.config/syncthing";
          }
        )
      ]);
    in
    {
      checks.sync-module-spec = builtins.seq (assertSpec goodEval.config) (
        pkgs.runCommand "sync-module-spec" { } ''
          touch $out
        ''
      );

      checks.sync-module-spec-configdir-nested =
        pkgs.runCommand "sync-module-spec-configdir-nested" { }
          ''
            if [ "${toString badConfigDirEval.success}" = "true" ]; then
              echo "expected evaluation failure but got success" >&2
              exit 1
            fi
            touch $out
          '';
    };
}
