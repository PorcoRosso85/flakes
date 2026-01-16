# Helix: generate languages.toml into the Nix store
#
# This module will aggregate Helix config declared by `parts/languages/*`
# and generate a single `languages.toml` store artifact.
{ ... }:
{
  perSystem = { ... }: { };
}
