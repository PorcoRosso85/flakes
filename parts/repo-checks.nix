{ ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      src = ../.;
    in
    {
      checks.no-internal-legacy-cue-import =
        pkgs.runCommand "no-internal-legacy-cue-import"
          {
            nativeBuildInputs = [
              pkgs.ripgrep
              pkgs.gnugrep
              pkgs.coreutils
            ];
          }
          ''
            set -euo pipefail

            hits="$(${pkgs.ripgrep}/bin/rg -n 'parts/cue\.nix' "${src}" || true)"
            if [[ -z "$hits" ]]; then
              touch "$out"
              exit 0
            fi

            bad="$(${pkgs.coreutils}/bin/printf '%s\n' "$hits" | ${pkgs.gnugrep}/bin/grep -vE '(/|^)README\.md:|(/|^)parts/cue\.nix:' || true)"
            if [[ -n "$bad" ]]; then
              echo "legacy import reference found (allowed: README.md, parts/cue.nix shim only):" >&2
              echo "$bad" >&2
              exit 1
            fi

            touch "$out"
          '';
    };
}
