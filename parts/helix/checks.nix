# Helix checks
#
# This module will add `checks.helix-*` to validate:
# - commands referenced by generated `languages.toml` are on PATH
# - `hx --health` does not report missing commands
{ ... }:
{
  perSystem = { ... }: { };
}
