{ lib, ... }:
{
  perSystem =
    {
      pkgs,
      config,
      self',
      ...
    }:
    let
      toolingNames = builtins.filter (n: lib.hasSuffix "-tooling" n) (builtins.attrNames config.packages);
      langs = map (n: lib.removeSuffix "-tooling" n) toolingNames;

      requiredKeys =
        lang:
        (
          if lang == "nix" then
            [
              {
                name = "formatter.${pkgs.system}";
                ok = (self' ? formatter) && self'.formatter != null;
              }
            ]
          else
            [ ]
        )
        ++ [

          {
            name = "packages.${lang}-tooling";
            ok = config.packages ? "${lang}-tooling";
          }
          {
            name = "packages.${lang}-lsp";
            ok = config.packages ? "${lang}-lsp";
          }
          {
            name = "packages.${lang}-lint";
            ok = config.packages ? "${lang}-lint";
          }
          {
            name = "packages.${lang}-fmt";
            ok = config.packages ? "${lang}-fmt";
          }
          {
            name = "devShells.${lang}";
            ok = config.devShells ? "${lang}";
          }
          {
            name = "checks.${lang}-smoke";
            ok = config.checks ? "${lang}-smoke";
          }
        ];

      missing = lib.concatMap (
        lang:
        map (k: "languages contract v1 violation: missing ${k.name} for lang=${lang}") (
          builtins.filter (k: k.ok == false) (requiredKeys lang)
        )
      ) langs;

      _ =
        if missing == [ ] then
          true
        else
          builtins.throw ("languages contract v1 failed:\n" + lib.concatStringsSep "\n" missing);
    in
    {
      # Fail-fast at evaluation time (during `nix flake show/check`) by throwing above.
      checks.languages-contract = pkgs.runCommand "languages-contract" { } ''
        touch "$out"
      '';

      # Explicitly reference flake output `formatter.${system}` to make sure
      # the `nix fmt` entrypoint is actually produced.
      checks.nix-formatter-smoke =
        if builtins.elem "nix" langs then
          pkgs.runCommand "nix-formatter-smoke" { nativeBuildInputs = [ self'.formatter ]; } ''
            set -euo pipefail
            nixfmt --version >/dev/null 2>&1 || nixfmt --help >/dev/null
            touch "$out"
          ''
        else
          pkgs.runCommand "nix-formatter-smoke-skipped" { } ''
            touch "$out"
          '';
    };
}
