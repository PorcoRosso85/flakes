# Phase1 Entrypoint Policy

## SSOT

- Phase1 の起動口は **`nix develop ./repos/flakes -c lazygit`** を SSOT とする

## 禁止事項

- `nix run` によるエントリポイント（`apps.*`）は **提供しない**（run禁止）

## 補足

- `packages.<system>.lazygit` は devShell の実装部品として存在してよい（ただし run の入口にはしない）
