# Helix devShell
#
# This module will provide `devShells.helix` and a shellHook that:
# - isolates HOME/XDG_* into $TMPDIR
# - enforces 2-step symlink contract for `.helix/languages.toml`
# - updates `.helix/languages.store.toml` (ignored) to point at the store artifact
{ ... }:
{
  perSystem = { ... }: { };
}
