# override-guard (purpose)

## 意義（=なぜ必要か）

- 「delta必須化できてないのに、できてると誤認する」事故を潰す
  - `.git/lazygit.yml` や 親ディレクトリの `.lazygit.yml` は global config を上書きするため、存在すると delta pager のSSOTが壊れ得る
- 原因特定コストをゼロ化する
  - diff が delta にならないとき、まず override 検出ログを見れば切り分けが終わる
- 運用の意思決定を固定する
  - 「止める/止めない」を決めないとDoDが曖昧でテスト不能になる
