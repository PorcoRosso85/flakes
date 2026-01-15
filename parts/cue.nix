# DEPRECATED: use `parts/languages/cue.nix`
#
# Compatibility shim for external consumers that still import `./parts/cue.nix`.
# This module delegates to `parts/languages/cue.nix`.

builtins.trace
  "DEPRECATED: import parts/languages/cue.nix (parts/cue.nix will be removed after migration)"
  (
    { ... }:
    {
      imports = [ ./languages/cue.nix ];
    }
  )
