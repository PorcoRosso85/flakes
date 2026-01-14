{
  pkgs,
  project,
  secretRoot ? "$HOME/.secret",
  packages ? [
    pkgs.git
    pkgs.gh
  ],
  shellHook ? "",
}:
let
  secretBase = "${secretRoot}/${project}";
  key = "${secretBase}/ssh/id_ed25519";
  knownHosts = "${secretBase}/ssh/known_hosts";
  tokenFile = "${secretBase}/gh/token";
  ghConfigDir = "${secretBase}/gh/config";
in
pkgs.mkShell {
  inherit packages;
  shellHook = ''
    set -euo pipefail

    # tools check
    for c in git gh ssh; do
      command -v "$c" >/dev/null 2>&1 || { echo "[devshell] missing command: $c" >&2; exit 1; }
    done

    # project mismatch guard
    repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
    current_dir="''${PWD:-}"
    project_detected=false

    # Check multiple patterns
    if [[ "$repo_root" == *"/${project}"* ]] || [[ "$repo_root" == *"${project}" ]]; then
      project_detected=true
    elif [[ "$current_dir" == *"/${project}"* ]] || [[ "$current_dir" == *"${project}" ]]; then
      project_detected=true
    elif [[ "$repo_root" == *"/repos/"* ]] && [[ "$repo_root" == *"/${project}"* ]]; then
      project_detected=true
    elif [[ -f "${secretBase}/ssh/id_ed25519" ]]; then
      project_detected=true
    fi

    if [[ "$project_detected" != "true" ]]; then
      echo "[devshell] project mismatch: project=${project}" >&2
      echo "[devshell] git_root=$repo_root pwd=$current_dir" >&2
      exit 1
    fi

    # secrets existence check
    [[ -r "${key}"        ]] || { echo "[devshell] missing ssh key: ${key}" >&2; exit 1; }
    [[ -r "${knownHosts}" ]] || { echo "[devshell] missing known_hosts: ${knownHosts}" >&2; exit 1; }
    [[ -r "${tokenFile}"  ]] || { echo "[devshell] missing GH token: ${tokenFile}" >&2; exit 1; }

    # token non-empty check
    export GH_TOKEN="$(tr -d '"'"'\n'"'"' < "${tokenFile}")"
    [[ -n "$GH_TOKEN" ]] || { echo "[devshell] GH token is empty: ${tokenFile}" >&2; exit 1; }

    # GH_CONFIG_DIR (ensure it exists)
    mkdir -p "${ghConfigDir}" 2>/dev/null || true
    export GH_CONFIG_DIR="${ghConfigDir}"

    # git/gh isolation
    export GIT_CONFIG_GLOBAL=/dev/null
    export GIT_CONFIG_SYSTEM=/dev/null
    export GIT_SSH_COMMAND="ssh -F /dev/null -i ${key} -o IdentitiesOnly=yes -o UserKnownHostsFile=${knownHosts} -o StrictHostKeyChecking=yes"

    unset GITHUB_TOKEN

    # custom shellHook (from flake.nix)
    ${shellHook}
  '';
}
