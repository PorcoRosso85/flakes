# Helix: generate languages.toml into the Nix store
#
# Aggregates `helix.*` declarations from `parts/languages/*`.
{ lib, ... }:
{
  perSystem =
    { pkgs, config, ... }:
    let
      toml = pkgs.formats.toml { };

      languageServerTable = lib.mapAttrs (_: srv: {
        command = srv.command;
        args = srv.args;
      }) config.helix.languageServers;

      languageList = lib.mapAttrsToList (
        name: langCfg:
        {
          inherit name;
          "language-servers" = langCfg.languageServers;
        }
        // lib.optionalAttrs (langCfg.formatter != null) {
          formatter = {
            command = langCfg.formatter.command;
            args = langCfg.formatter.args;
          };
        }
      ) config.helix.languages;

      helixToml = {
        "language-server" = languageServerTable;
        language = languageList;
      };

      languagesToml = toml.generate "helix-languages.toml" helixToml;
    in
    {
      helix.languagesToml = languagesToml;
    };
}
