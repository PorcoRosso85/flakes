# Phase1 acceptance (lazygit-delta)

## 目的

- Phase1 の SSOT 起動口を `nix develop ./repos/flakes -c lazygit` に固定する
- lazygit の diff 表示 pager が delta の **side-by-side** になることを確認する
- override-guard（B: 警告して継続）が効いていることを確認する

## 事前条件

- この手順は `./repos/flakes` を対象にする

## 🧾 証拠（最低限）

- 🧾 `nix flake check ./repos/flakes` の成功ログ
- 🧾 override 無し/有りの 2 ケースで、stderr を保存
- 🧾 side-by-side の目視（スクショ or 録画）

## 1) flake check（回帰検知）

```bash
nix flake check ./repos/flakes
```

保存:
- stdout/stderr（成功ログ）

## 2) override-guard（2ケース）

### Case A: override なし（警告が出ない）

```bash
tmp_repo="$(mktemp -d)"
git -C "$tmp_repo" init
(cd "$tmp_repo" && nix develop ./repos/flakes -c lazygit -- --version) 2>case-a.stderr
```

期待:
- `case-a.stderr` に `[lazygit-delta] WARNING:` が出ない

### Case B: override あり（警告が出るが継続）

```bash
tmp_repo="$(mktemp -d)"
git -C "$tmp_repo" init
touch "$tmp_repo/.lazygit.yml"
(cd "$tmp_repo" && nix develop ./repos/flakes -c lazygit -- --version) 2>case-b.stderr
```

期待:
- `case-b.stderr` に `[lazygit-delta] WARNING:` が出る
- `case-b.stderr` に `override: <path>` が出る

保存:
- `case-a.stderr`
- `case-b.stderr`

## 3) side-by-side 目視

```bash
# 任意のgit repoで
nix develop ./repos/flakes -c lazygit
```

確認:
- diff 表示が delta により side-by-side になっている

保存:
- スクショ or 録画（side-by-side が分かるもの）
