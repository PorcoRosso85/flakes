# override-guard acceptance

## 最小DoD

- overrideが無いrepo: 警告が出ない
- overrideがあるrepo: **警告が出る**（stderr）・起動は継続

## 🧾 証拠の作り方（例）

1) ダミーrepoを作る

- case A: override無し
- case B: override有り（repo root か 親dirに `.lazygit.yml` を置く、または `.git/lazygit.yml` を置く）

2) それぞれ `nix run .#lazygit` を実行し、stderr を保存する

- case A: stderr に `[lazygit-delta] WARNING:` が出ない
- case B: stderr に `[lazygit-delta] WARNING:` と、検出パスが出る
