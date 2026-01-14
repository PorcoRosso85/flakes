# mkLazygitDelta: lazygit を「同梱(生成)config + delta pager」で起動するモジュール
#
# 注意: --use-config-dir に Nix store 直下を渡すと、state/log を書けずクラッシュし得る。
# そのため config.yml は store 生成し、実行時に writable dir へコピーして使う。
{
  pkgs,
  deltaPager ? null,
}:
let
  yaml = pkgs.formats.yaml { };

  deltaPagerWrapper = pkgs.writeShellScriptBin "lazygit-delta-pager" ''
    set -euo pipefail

    column_width=""
    args=()

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --column-width=*)
          column_width="''${1#*=}"
          shift
          ;;
        --column-width)
          column_width="''${2:-}"
          shift 2
          ;;
        *)
          args+=("$1")
          shift
          ;;
      esac
    done

    if [[ -n "$column_width" ]] && [[ "$column_width" =~ ^[0-9]+$ ]]; then
      export LAZYGIT_DELTA_COLUMN_WIDTH="$column_width"
      export LAZYGIT_DELTA_WIDTH="$(( column_width * 2 + 1 ))"
      exec ${pkgs.delta}/bin/delta --width="$LAZYGIT_DELTA_WIDTH" "''${args[@]}"
    fi

    exec ${pkgs.delta}/bin/delta "''${args[@]}"
  '';

  effectiveDeltaPager =
    if deltaPager != null then
      deltaPager
    else
      "${deltaPagerWrapper}/bin/lazygit-delta-pager --column-width={{columnWidth}} --side-by-side --paging=never";

  cfgFile = yaml.generate "config.yml" {
    git = {
      pagers = [
        {
          colorArg = "always";
          pager = effectiveDeltaPager;
        }
      ];
    };
  };

  package = pkgs.writeShellScriptBin "lazygit" ''
    set -euo pipefail

    export PATH="${
      pkgs.lib.makeBinPath [
        pkgs.coreutils
        pkgs.git
        pkgs.delta
      ]
    }:$PATH"

    tmp_base="''${XDG_RUNTIME_DIR:-''${TMPDIR:-/tmp}}"
    cfg_dir="$(mktemp -d "$tmp_base/lazygit-config.XXXXXXXX")"

    cleanup() {
      rm -rf "$cfg_dir"
    }
    trap cleanup EXIT

    cp ${cfgFile} "$cfg_dir/config.yml"

    # `lazygit --version` は環境によって /dev/tty を要求して失敗し得るため、
    # TTY不要な範囲では wrapper 側でバージョン文字列を返す。
    for arg in "$@"; do
      if [[ "$arg" == "--version" ]] || [[ "$arg" == "-v" ]]; then
        printf 'lazygit %s\n' "${pkgs.lazygit.version}"
        exit 0
      fi
    done

    warn() {
      printf '%s\n' "$*" >&2
    }

    git_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
    override_found=false

    if [[ -n "$git_root" ]]; then
      if [[ -f "$git_root/.git/lazygit.yml" ]]; then
        if [[ "$override_found" != "true" ]]; then
          warn "[lazygit-delta] WARNING: detected config overrides; delta formatting is not guaranteed"
          override_found=true
        fi
        warn "[lazygit-delta] override: $git_root/.git/lazygit.yml"
      fi

      # lazygit は repo 固有設定として、repo の親ディレクトリにある .lazygit.yml も読み込む。
      # 仕様どおり親を辿って検出する（repo root も含めて警告対象にする）。
      dir="$git_root"
      while :; do
        if [[ -f "$dir/.lazygit.yml" ]]; then
          if [[ "$override_found" != "true" ]]; then
            warn "[lazygit-delta] WARNING: detected config overrides; delta formatting is not guaranteed"
            override_found=true
          fi
          warn "[lazygit-delta] override: $dir/.lazygit.yml"
        fi

        parent="''${dir%/*}"
        if [[ -z "$parent" ]]; then parent="/"; fi
        if [[ "$parent" == "$dir" ]]; then break; fi
        dir="$parent"
      done

      if [[ "$override_found" == "true" ]]; then
        warn "[lazygit-delta] NOTE: remove/move overrides to make delta pager SSOT"
      fi
    fi

    exec ${pkgs.lazygit}/bin/lazygit --use-config-dir "$cfg_dir" "$@"
  '';

in
{
  inherit package cfgFile;
}
