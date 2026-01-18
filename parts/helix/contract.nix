# Helix SSOT schema (perSystem options)
{ lib, ... }:
{
  perSystem =
    { ... }:
    {
      options.helix = {
        tools = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          description = "Packages declared by language parts (SSOT inputs).";
        };

        requiredPkgs = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          readOnly = true;
          description = "Minimal package set derived from helix SSOT (used by checks).";
        };

        languageServers = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                # NOTE: Keep this a string (not a list). Use `args` for arguments.
                command = lib.mkOption { type = lib.types.str; };
                args = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                };
              };
            }
          );
          default = { };
        };

        languages = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                languageServers = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                };

                formatter = lib.mkOption {
                  type = lib.types.nullOr (
                    lib.types.submodule {
                      options = {
                        # NOTE: Keep this a string (not a list). Use `args` for arguments.
                        command = lib.mkOption { type = lib.types.str; };
                        args = lib.mkOption {
                          type = lib.types.listOf lib.types.str;
                          default = [ ];
                        };
                      };
                    }
                  );
                  default = null;
                };
              };
            }
          );
          default = { };
        };

        languagesToml = lib.mkOption {
          type = lib.types.path;
          readOnly = true;
          description = "Store path to generated Helix languages.toml.";
        };

        commandsList = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          readOnly = true;
          description = "Command names required by Helix tooling (CI truth).";
        };

      };
    };
}
