{ lib, ... }:
{
  perSystem =
    { config, ... }:
    let
      toolingNames = builtins.filter (n: lib.hasSuffix "-tooling" n) (builtins.attrNames config.packages);
      langs = map (n: lib.removeSuffix "-tooling" n) toolingNames;

      mkAssert = lang: kind: {
        assertion = kind.exists;
        message = "languages contract v1 violation: missing ${kind.name} for lang=${lang}";
      };

      required = lang: [
        {
          name = "packages.${lang}-tooling";
          exists = config.packages ? "${lang}-tooling";
        }
        {
          name = "packages.${lang}-lsp";
          exists = config.packages ? "${lang}-lsp";
        }
        {
          name = "packages.${lang}-lint";
          exists = config.packages ? "${lang}-lint";
        }
        {
          name = "packages.${lang}-fmt";
          exists = config.packages ? "${lang}-fmt";
        }
        {
          name = "devShells.${lang}";
          exists = config.devShells ? "${lang}";
        }
        {
          name = "checks.${lang}-smoke";
          exists = config.checks ? "${lang}-smoke";
        }
      ];

      assertions = lib.concatMap (lang: map (k: mkAssert lang k) (required lang)) langs;
    in
    {
      inherit assertions;
    };
}
