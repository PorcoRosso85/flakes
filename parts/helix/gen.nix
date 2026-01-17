# Helix: generate store artifacts from SSOT
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

      commandsList = lib.unique (
        (lib.mapAttrsToList (_: s: s.command) config.helix.languageServers)
        ++ (lib.concatMap (l: if l.formatter == null then [ ] else [ l.formatter.command ]) (
          lib.mapAttrsToList (_: v: v) config.helix.languages
        ))
      );

      languagesTomlRaw = toml.generate "helix-languages.toml" helixToml;
      commandsJsonRaw = pkgs.writeText "helix-commands.json" (builtins.toJSON commandsList);

      helixStore = pkgs.runCommand "helix" { } ''
        set -euo pipefail
        mkdir -p "$out"
        ln -s "${languagesTomlRaw}" "$out/languages.toml"
        ln -s "${commandsJsonRaw}" "$out/commands.json"
      '';
    in
    {
      helix.languagesToml = "${helixStore}/languages.toml";
      helix.commandsJson = "${helixStore}/commands.json";
      helix.commandsList = commandsList;
    };
}
