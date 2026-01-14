# override-guard acceptance

この手順は Phase1 の受け入れ手順に統合した。

- 正本: `parts/lazygit-delta/acceptance/phase1.md`

## 最小DoD（抜粋）

- override が無い repo: 警告が出ない
- override がある repo: **警告が出る**（stderr）・起動は継続

## 🧾 証拠の作り方（抜粋）

- `nix develop ./repos/flakes -c lazygit -- --version` の stderr を保存する（2ケース）
