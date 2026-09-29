# arch-debian-restore

Arch & Debian Linxマシンをゼロから復元するためのリポジトリ。
GPG本人鍵ceremony・privateリポジトリへの依存をやめ、共通パスフレーズと
Dropbox配布だけで、複数のマシンのどれからでも復元できる状態を目指す。

## 配布方針

- 日常のブートストラップでは `git clone` を一切使わない
- Dropboxクライアントを手動インストールし、同期完了を待つだけで
  `~/Dropbox/arch-debian-restore/` として実体が出現する
- このGitHubリポジトリは、あくまで保険用の複製（秘密情報は含まない）

## 0段階（唯一の手動ステップ）

netinstall / archinstall 直後の裸環境には git・make・Dropbox が無い
（Arch/EndeavourOSの場合はyay・git・makeが標準搭載のため、実質Dropboxのみ）。

**このREADMEはこのGitHubページ自体を、そのマシンのFirefox（Live環境/
インストール後どちらにも入っている）で 'https://github.com/minorugh' 開いて、
'arch-debian-restore/README.md' から以下のコマンドをそのままコピペすればよい。手で打つ必要はない。**

1. Dropboxクライアントをインストールする（Arch/Debian共通コマンド）
   ```bash
   cd ~ && wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf -
   ~/.dropbox-dist/dropboxd
   ```
   初回起動時にアカウント連携用のURLが表示される。そのURLをクリックして
   ブラウザでログインする。
2. 同期完了を待つ
   → `~/Dropbox/arch-debian-restore/`（`1st.sh`・`Makefile`・
     `env.bundle.gpg` 等を含む）が実体として出現する
3. `1st.sh` を実行する（Debianの場合のみgit・makeを導入。Archでは
   確認のみで何もしない）
   ```bash
   cd ~/Dropbox/arch-debian-restore
   bash 1st.sh
   ```

ここまで終われば、以降は全て `make` コマンドで進行できる。

### Live環境で日本語キーボードにならない場合

Debian Live / EndeavourOS Liveでは、日本語キーボード配列が設定されておらず、
`:` などのキーがUS配列になることがある。

その場合はターミナルで以下を実行する。

```bash
setxkbmap jp
```

（Archでのデスクトップ統合＝トレイアイコン表示は、後で `make aur` を実行
すると自動的に切り替わる。0段階では気にしなくてよい）

## 前提

- 上記「0段階」が完了していること（`git`・`make` が導入済み）
- Dropbox同期が完了し、`~/Dropbox/backup/env/env.bundle.gpg` が
  存在すること

## 使い方

```bash
cd ~/Dropbox/arch-debian-restore
make env-restore # 対話式。env.bundle.gpgを復号し ~/.env_source・abookを復元する
make ssh-setup   # 対話式。SSH鍵をこのマシン専用に新規生成し、config/known_hosts展開・GitHub登録を案内する
make all         # dotfiles → github
```

`env-restore` は GitHub への SSH 接続を必要としない（Dropbox上のファイルをローカルで
復号・cloneするだけ）ため、`ssh-setup` より先に実行できる。この順序で実行することで、
`ssh-setup` の時点で `~/.env_source/.ssh` 配下の config テンプレートを展開でき、
以降の `dotfiles`・`github` は最初から `git@` （SSH）でclone可能になる。

## Makefileターゲット一覧

| ターゲット | 内容 |
|---|---|
| `env-restore` | Dropbox上の `env.bundle.gpg` と最新のabookを復元する |
| `ssh-setup` | SSH鍵をこのマシン専用に新規生成し、config/known_hosts展開・GitHub登録・keychain設定までを案内する |
| `dotfiles` | `dotfiles` リポジトリをclone |
| `github` | その他の個人リポジトリ群をclone |
| `github-dropbox-cleanup` | `GH`・`minorugh.com`・`arch-debian-restore` はclone後 `.git` 以外を削除（実体はDropbox、競合回避。`github` から自動実行） |
| `github-remote-add` | `GH`・`minorugh.com` に自前サーバー(xserver)・自前Git GUI(Gitea)のpushurlを追加（対話式、`##!`。Docker/Gitea起動後に手動実行） |
| `git` | `git add -A` → 変更があればcommit。P1機ではpush、サブ機ではpull --rebase |
| `all` | `dotfiles` → `github` をまとめて実行 |
| `help` | ターゲット一覧を表示する |

`env-restore`・`ssh-setup` はいずれも対話的な手順を挟むため、`all` には含めず
個別に先に実行する運用にしている。`ssh-setup` は `~/.env_source/.ssh` の内容を
参照するため、必ず `env-restore` の後に実行すること。

`github-remote-add` も対話式（`##!`）で、かつ自前サーバー・自前Git GUI（Gitea等）が
起動済みであることが前提のため、`all` には含めず環境構築が一通り終わった後に
手動実行する運用にしている（詳細は下記「GitHub private リポジトリの保険運用について」）。

## GitHub private リポジトリの保険運用について

GitHubの利用規約変更やアカウント制限など、private リポジトリが
将来アクセス不能になるリスクに備え、一部のリポジトリは
GitHub 以外にも remote を持たせている。

### 考え方

判断基準は「このリポジトリが private かどうか」の1点。
public リポジトリは GitHub 側の制限対象になり得ないため、
GitHub 単独で十分という考え方をとっている。

private のうち、特に失うと復旧作業自体が止まってしまう
「致命傷インフラ」に該当するリポジトリ（`GH`・`minorugh.com`）だけ、
以下の2つを追加の remote として持たせている。

- **自前の Git サーバー**（bare リポジトリ、xserver上）: 実データそのものの
  第三の保管場所。GitHub が使えなくなった場合の最終防衛ライン。
- **自前の Git GUI**（Gitea をセルフホスト）: bare リポジトリは
  Web UI を持たないため、その代替として並行運用。

`origin` に `pushurl` を複数登録することで、`git push` 一発で
GitHub・自前サーバー・自前GUIの全てに同時送信される。
`fetch` は GitHub のみに固定し、取得元は単一に保っている。

```bash
git remote -v
# origin  git@github.com:xxx/repo.git (fetch)
# origin  git@github.com:xxx/repo.git (push)
# origin  xsrv:/home/minorugh/git/repo.git (push)
# origin  http://localhost:3000/minoru/repo.git (push)
```

### 注意点

- `github-remote-add` は対象サービス（Gitea等）が起動済みであることが
  前提になるため、`env-restore`/`ssh-setup`/`dotfiles`/`github` のような
  一連のリストア処理には含めず、環境構築が一通り終わった後に
  手動実行する運用にしている
- `GH`・`minorugh.com` は実体を別ディレクトリ（Dropbox）で管理し、
  `.git`本体だけをここに置く構成のため、clone直後に作業ファイル一式が
  展開されてしまう。これを`.git`のみに整理するのが`github-dropbox-cleanup`
  （`github`ターゲットから自動実行される）

## このリポジトリに含まれないもの

秘密鍵・パスフレーズ・`env.bundle.gpg` 本体は含まれません。これらは
すべて `~/Dropbox/arch-debian-restore/` を通じて（Dropbox同期経由で）配布される。

## 補足

`arch-debian-restore` はGH・minorugh.comと同様に「Dropbox実体 + gitdirリンク」
方式（`github-dropbox-cleanup` で `.git` 以外を削除する運用）に揃えてある。
GitHub側への更新は `git` ターゲットで行い、P1機からのみpushし、サブ機は
`pull --rebase` のみを行う。
