# Helix SSOT schema (flake-parts module options)
{ lib, ... }:
{
  options.helix = {
    tools = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Packages to add to devShells.helix PATH.";
    };

    languageServers = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
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
  };
}
