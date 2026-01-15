{ ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      src = ../.;
    in
    {
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

      checks.no-legacy-cue-artifacts =
        pkgs.runCommand "no-legacy-cue-artifacts"
          {
            nativeBuildInputs = [
              pkgs.ripgrep
              pkgs.coreutils
            ];
          }
          ''
            set -euo pipefail

            # File must not exist
            legacy_path="${src}/parts/""cue.nix"
            if [[ -e "$legacy_path" ]]; then
              echo "unexpected legacy file exists: parts/""cue.nix" >&2
              exit 1
            fi

            # Patterns must not exist anywhere in repo source.
            pat1="parts/""cue.nix"
            pat2="no-internal-legacy-cue-""import"
            pat3="cue-""v15"

            for pat in "$pat1" "$pat2" "$pat3"; do
              hits="$(${pkgs.ripgrep}/bin/rg -n --fixed-strings "$pat" "${src}" || true)"
              if [[ -n "$hits" ]]; then
                echo "unexpected legacy artifact present: $pat" >&2
                echo "$hits" >&2
                exit 1
              fi
            done

            touch "$out"
          '';
    };
}
