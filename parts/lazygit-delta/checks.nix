# mkChecks: 最小の回帰検知（config生成とwrapperの要点だけ）
{
  pkgs,
  package,
  cfgFile,
}:
{
  lazygit-delta = pkgs.runCommand "check-lazygit-delta" { } ''
    set -euo pipefail

    # 1) 生成された config.yml に delta 指定が入っている
    ${pkgs.gnugrep}/bin/grep -qE 'pager:.*delta' ${cfgFile}
    ${pkgs.gnugrep}/bin/grep -q -- '--paging=never' ${cfgFile}

    # 2) wrapper が --use-config-dir を使っている
    ${pkgs.gnugrep}/bin/grep -q -- '--use-config-dir' ${package}/bin/lazygit

    # 3) store 直指定回帰を防ぐ: writable dir を作っている
    ${pkgs.gnugrep}/bin/grep -q -- 'mktemp -d' ${package}/bin/lazygit

    # 4) 起動可能（TTY不要範囲）
    ${package}/bin/lazygit --version >/dev/null

    touch "$out"
  '';
}
