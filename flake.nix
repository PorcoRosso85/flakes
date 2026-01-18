{
  description = "packages-first flake: repo ops, edit, and minimal language tooling";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    opencode = {
      url = "github:anomalyco/opencode/v1.1.6";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    let
      result = flake-parts.lib.mkFlake { inherit inputs; } {
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];

        perSystem =
          { pkgs, ... }:
          let
            sys = pkgs.system;
            oc = inputs.opencode;

            hasOpencodePkg =
              oc ? packages.${sys} && (oc.packages.${sys} ? opencode || oc.packages.${sys} ? default);
            hasOpencodeApp = oc ? apps.${sys} && (oc.apps.${sys} ? opencode || oc.apps.${sys} ? opencode-dev);

            opencodeUpstream =
              if hasOpencodePkg then
                oc.packages.${sys}.opencode or oc.packages.${sys}.default
              else if hasOpencodeApp then
                pkgs.writeShellApplication {
                  name = "opencode";
                  text = ''exec ${oc.apps.${sys}.opencode or oc.apps.${sys}.opencode-dev.program} "$@"'';
                }
              else
                throw "inputs.opencode must expose packages.${sys}.opencode/default or apps.${sys}.opencode/opencode-dev";

            opencodeConfig = ./parts/opencode/config/opencode-lsp.json;

            opencode = pkgs.writeShellApplication {
              name = "opencode";
              meta.mainProgram = "opencode";
              text = ''
                export OPENCODE_CONFIG="${opencodeConfig}"
                exec ${opencodeUpstream}/bin/opencode "$@"
              '';
            };

            pythonEnv = pkgs.python3.withPackages (ps: [ ps.pytest ]);

            gitTools = pkgs.buildEnv {
              name = "git-tools";
              paths = [
                pkgs.git
                pkgs.gh
                pkgs.lazygit
              ];
            };

            editorTools = pkgs.buildEnv {
              name = "editor-tools";
              paths = [
                pkgs.helix
                opencode
              ];
            };

            pythonTooling = pkgs.buildEnv {
              name = "python-tooling";
              paths = [
                pythonEnv
                pkgs.ruff
                pkgs.pyright
              ];
            };

            goTooling = pkgs.buildEnv {
              name = "go-tooling";
              paths = [
                pkgs.go
                pkgs.gopls
              ];
            };

            rustTooling = pkgs.buildEnv {
              name = "rust-tooling";
              paths = [
                pkgs.cargo
                pkgs.rustc
                pkgs.rust-analyzer
              ];
            };

            testIntegration = pkgs.writeShellApplication {
              name = "test.integration";
              meta.mainProgram = "test.integration";
              text = ''
                set -euo pipefail

                fail() {
                  echo "[test.integration] $*" >&2
                  exit 1
                }

                assert_has() {
                  local cmd="$1"
                  command -v "$cmd" >/dev/null 2>&1 || fail "missing required command: $cmd"
                }

                assert_not() {
                  local cmd="$1"
                  if command -v "$cmd" >/dev/null 2>&1; then
                    fail "forbidden command present: $cmd"
                  fi
                }

                check_has_many() {
                  local label="$1"
                  shift
                  for c in "$@"; do
                    assert_has "$c"
                  done
                  echo "[test.integration] ok: $label (required)"
                }

                check_not_many() {
                  local label="$1"
                  shift
                  for c in "$@"; do
                    assert_not "$c"
                  done
                  echo "[test.integration] ok: $label (forbidden)"
                }

                # git-tools
                PATH="${gitTools}/bin"
                check_has_many "git-tools" git gh lazygit
                check_not_many "git-tools" hx opencode python pytest ruff pyright go gopls cargo rustc rust-analyzer

                # editor-tools
                PATH="${editorTools}/bin"
                check_has_many "editor-tools" hx opencode
                check_not_many "editor-tools" python pytest ruff pyright go gopls cargo rustc rust-analyzer

                # python-tooling
                PATH="${pythonTooling}/bin"
                check_has_many "python-tooling" python pytest ruff pyright
                check_not_many "python-tooling" hx opencode gh lazygit

                # go-tooling
                PATH="${goTooling}/bin"
                check_has_many "go-tooling" go gopls
                check_not_many "go-tooling" hx opencode gh lazygit

                # rust-tooling
                PATH="${rustTooling}/bin"
                check_has_many "rust-tooling" cargo rustc rust-analyzer
                check_not_many "rust-tooling" hx opencode gh lazygit

                echo "[test.integration] success"
              '';
            };

            testE2E = pkgs.writeShellApplication {
              name = "test.e2e";
              meta.mainProgram = "test.e2e";
              text = ''
                set -euo pipefail

                fail() {
                  echo "[test.e2e] $*" >&2
                  exit 1
                }

                assert_has() {
                  local cmd="$1"
                  command -v "$cmd" >/dev/null 2>&1 || fail "missing required command: $cmd"
                }

                check_combo() {
                  local label="$1"
                  local path="$2"
                  shift 2
                  PATH="$path"
                  for c in "$@"; do
                    assert_has "$c"
                  done
                  echo "[test.e2e] ok: $label"
                }

                check_combo "editor+python" "${editorTools}/bin:${pythonTooling}/bin" hx opencode python pytest ruff pyright
                check_combo "editor+go" "${editorTools}/bin:${goTooling}/bin" hx opencode go gopls
                check_combo "editor+rust" "${editorTools}/bin:${rustTooling}/bin" hx opencode cargo rustc rust-analyzer
                check_combo "git+editor+python" "${gitTools}/bin:${editorTools}/bin:${pythonTooling}/bin" git gh lazygit hx opencode python

                echo "[test.e2e] success"
              '';
            };

            checkIntegration =
              pkgs.runCommand "flake-check.integration" { nativeBuildInputs = [ testIntegration ]; }
                ''
                  ${testIntegration}/bin/test.integration
                  touch $out
                '';

            checkE2E = pkgs.runCommand "flake-check.e2e" { nativeBuildInputs = [ testE2E ]; } ''
              ${testE2E}/bin/test.e2e
              touch $out
            '';
          in
          {
            packages = {
              git-tools = gitTools;
              editor-tools = editorTools;
              python-tooling = pythonTooling;
              go-tooling = goTooling;
              rust-tooling = rustTooling;

              test-integration = testIntegration;
              test-e2e = testE2E;
            };

            devShells = {
              default = pkgs.mkShell {
                packages = [ gitTools ];
              };

              edit = pkgs.mkShell {
                packages = [ editorTools ];
              };
            };

            checks = {
              integration = checkIntegration;
              e2e = checkE2E;
            };
          };
      };

      apps = builtins.mapAttrs (system: systemPkgs: {
        integration = {
          type = "app";
          program = "${systemPkgs.test-integration}/bin/test.integration";
        };

        e2e = {
          type = "app";
          program = "${systemPkgs.test-e2e}/bin/test.e2e";
        };
      }) result.packages;
    in
    result // { inherit apps; };
}
