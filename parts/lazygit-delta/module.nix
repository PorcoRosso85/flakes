# mkLazygitDelta: lazygit を「同梱(生成)config + delta pager」で起動するモジュール
#
# 注意: --use-config-dir に Nix store 直下を渡すと、state/log を書けずクラッシュし得る。
# そのため config.yml は store 生成し、実行時に writable dir へコピーして使う。
{
  pkgs,
  deltaPager ? "delta --paging=never",
}:
let
  yaml = pkgs.formats.yaml { };

  cfgFile = yaml.generate "config.yml" {
    git = {
      pagers = [
        {
          colorArg = "always";
          pager = deltaPager;
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

  app = {
    type = "app";
    program = "${package}/bin/lazygit";
  };
in
{
  inherit package cfgFile;
  app = app;
}
