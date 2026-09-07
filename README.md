# arch-debian-restore

Arch & Debian Linxマシンをゼロから復元するためのリポジトリ（旧 `env-import`）。
GPG本人鍵ceremony・privateリポジトリへの依存をやめ、共通パスフレーズと
Dropbox配布だけで、複数のマシンのどれからでも復元できる状態を目指す。

## 配布方針

- 日常のブートストラップでは `git clone` を一切使わない
- Dropboxクライアントを手動インストールし、同期完了を待つだけで
  `~/Dropbox/arch-restore/` として実体が出現する
- このGitHubリポジトリは、あくまで保険用の複製（秘密情報は含まない）

## 前提

- `git`・`make` がインストール済みであること
  ```bash
  sudo pacman -S --needed git make
  ```
- Dropbox同期が完了し、`~/Dropbox/arch-restore/env.bundle.gpg` が
  存在すること

## 使い方

```bash
cd ~/Dropbox/arch-restore
make ssh-setup   # 対話式。SSH鍵をこのマシン専用に新規生成し、GitHub登録を案内する
make all         # env-restore → dotfiles → github
```

## Makefileターゲット一覧

| ターゲット | 内容 |
|---|---|
| `ssh-setup` | SSH鍵をこのマシン専用に新規生成し、GitHub登録・keychain設定までを案内する |
| `env-restore` | Dropbox上の `env.bundle.gpg` と最新のabookを復元する |
| `dotfiles` | `dotfiles` リポジトリをclone |
| `github` | その他の個人リポジトリ群をclone |
| `all` | `env-restore` → `dotfiles` → `github` をまとめて実行 |
| `help` | ターゲット一覧を表示する |

`ssh-setup` はGitHub登録という対話的な手順を挟むため、`all` には含めず
単独で先に実行する運用にしている。

## このリポジトリに含まれないもの

秘密鍵・パスフレーズ・`env.bundle.gpg` 本体は含まれません。これらは
すべて `~/Dropbox/arch-restore/` を通じて（Dropbox同期経由で）配布される。

## 補足

現時点では、このマシンからGitHub側のarch-restoreリポジトリへ更新を
push する運用は用意していない。今後、GH・minorugh.comと同様の
「Dropbox実体 + gitdirリンク」方式での運用を検討中。
