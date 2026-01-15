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

            bad="$(${pkgs.coreutils}/bin/printf '%s\n' "$hits" | ${pkgs.gnugrep}/bin/grep -vE '(/|^)README\.md:|(/|^)parts/cue\.nix:|(/|^)parts/repo-checks\.nix:' || true)"
            if [[ -n "$bad" ]]; then
              echo "legacy import reference found (allowed: README.md, parts/cue.nix shim, parts/repo-checks.nix):" >&2
              echo "$bad" >&2
              exit 1
            fi

            touch "$out"
          '';

      checks.languages-decisions-no-unused-keys =
        pkgs.runCommand "languages-decisions-no-unused-keys"
          {
            nativeBuildInputs = [
              pkgs.ripgrep
              pkgs.gnugrep
              pkgs.coreutils
            ];
          }
          ''
            set -euo pipefail

            decisions="${src}/parts/languages/decisions.cue"
            test -f "$decisions"

            # Collect top-level cue field names: <ident>:
            keys="$(${pkgs.ripgrep}/bin/rg -o '^[A-Za-z_][A-Za-z0-9_]*(?=\s*:)' "$decisions" | ${pkgs.coreutils}/bin/sort -u || true)"

            allowed_file="$TMPDIR/allowed"
            ${pkgs.coreutils}/bin/cat >"$allowed_file" <<'EOF'
            ts_runtime_policy
            nix_formatter_choice
            zig_lint_policy
            breaking_remove_parts_cue
            EOF

            bad_keys="$(${pkgs.coreutils}/bin/printf '%s\n' "$keys" | ${pkgs.gnugrep}/bin/grep -vFx -f "$allowed_file" || true)"
            if [[ -n "$bad_keys" ]]; then
              echo "unexpected keys in parts/languages/decisions.cue:" >&2
              echo "$bad_keys" >&2
              exit 1
            fi

            touch "$out"
          '';
    };
}
