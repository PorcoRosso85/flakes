# mkChecks: 最小の回帰検知（config生成とwrapperの要点だけ）
{
  pkgs,
  package,
  cfgFile,
}:
{
  lazygit-delta = pkgs.runCommand "check-lazygit-delta" { } ''
    set -euo pipefail

    # 1) 生成された config.yml に delta 指定が入っている（side-by-side/paging/columnWidth）
    ${pkgs.gnugrep}/bin/grep -q -- 'lazygit-delta-pager' ${cfgFile}
    ${pkgs.gnugrep}/bin/grep -q -- '--side-by-side' ${cfgFile}
    ${pkgs.gnugrep}/bin/grep -q -- '--paging=never' ${cfgFile}
    ${pkgs.gnugrep}/bin/grep -q -- '--column-width={{columnWidth}}' ${cfgFile}

    # `--width={{columnWidth}}` の再導入（回帰）を防ぐ
    if ${pkgs.gnugrep}/bin/grep -q -- '--width={{columnWidth}}' ${cfgFile}; then
      echo "unexpected: --width={{columnWidth}} found in config" >&2
      exit 1
    fi

    # pager wrapper が幅を export している（デバッグ/切り分け用）
    pager_bin="$(${pkgs.gnugrep}/bin/grep -oE '/nix/store/[^" ]+/bin/lazygit-delta-pager' ${cfgFile} | ${pkgs.coreutils}/bin/head -n1)"
    test -n "$pager_bin"
    ${pkgs.gnugrep}/bin/grep -q -- 'LAZYGIT_DELTA_WIDTH' "$pager_bin"

    # 2) wrapper が --use-config-dir を使っている
    ${pkgs.gnugrep}/bin/grep -q -- '--use-config-dir' ${package}/bin/lazygit

    # 3) store 直指定回帰を防ぐ: writable dir を作っている
    ${pkgs.gnugrep}/bin/grep -q -- 'mktemp -d' ${package}/bin/lazygit

    # 4) 起動可能（TTY不要範囲）
    ${package}/bin/lazygit --version >/dev/null

    touch "$out"
  '';
}
