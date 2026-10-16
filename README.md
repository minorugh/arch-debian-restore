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
make env-restore # 対話式。env.bundle.gpgを復号し ~/.env_source を復元する
make ssh-setup   # 対話式。SSH鍵をこのマシン専用に新規生成し、config/known_hosts展開・GitHub登録を案内する
make all         # dotfiles → github
```

**以上の `make` コマンドは、必ずターミナルから実行すること。**
`env-restore`（gpgパスフレーズの入力）と `ssh-setup`（公開鍵のGitHub登録）は
対話式のため、Emacs の compile バッファ等からは実行できない。

`env-restore` は GitHub への SSH 接続を必要としない（Dropbox上のファイルをローカルで
復号・cloneするだけ）ため、`ssh-setup` より先に実行できる。この順序で実行することで、
`ssh-setup` の時点で `~/.env_source/.ssh` 配下の config テンプレートを展開でき、
以降の `dotfiles`・`github` は最初から `git@` （SSH）でclone可能になる。

### SSH鍵の命名規則と、クリーンリストア時の旧鍵の扱い

**命名規則**

- 鍵ファイル名は `id_ed25519_<hostname>` で固定する。共用の config テンプレート
  （`~/.env_source/.ssh/config`）の `IdentityFile ~/.ssh/id_ed25519_%l` と
  一致させるため、日付は入れない
- 鍵のコメント（`.pub` 末尾）は `ssh-setup` が `<hostname>-<YYYYMMDD>` で自動付与する
- GitHub登録時のTitleも、鍵ファイル名と同じ `id_ed25519_<hostname>` にしておく。
  **これは必須ではなく、管理上の取り決めである。** GitHubのTitleは単なるラベルで、
  接続の可否には関係しない（接続に必要なのは、登録した公開鍵と手元の秘密鍵が
  対になっていること）。ただ、Titleを鍵ファイル名に揃えておけば、一覧を見て
  どのマシンの鍵か分かる。日付は、コメントとGitHubの「Added on」で分かるので
  Titleには入れない

**クリーンリストア時は、旧鍵を先に削除する**

Titleを `id_ed25519_<hostname>` に揃える以上、旧鍵を残したまま新鍵を登録すると
同じTitleの鍵が2本並び、どちらが現役か分からなくなる（GitHubは登録後にTitleを
編集できないため、後から区別も付けられない）。そこで、同じマシンをクリーンリストア
する場合は、旧鍵を先に削除してから新鍵を登録する。旧秘密鍵はディスクごと消えて
いるので、旧公開鍵を残す意味もない。

1. GitHub → Settings → SSH and GPG keys で、このマシンの旧鍵を削除する
2. `make ssh-setup` で新鍵を生成し、同じページにTitleを `id_ed25519_<hostname>`
   にして登録する
3. `ssh -T git@github.com` で接続を確認する

**鍵の登録先は2か所（config の Host と対応）**

`~/.ssh/config` では、`Host github.com` と `Host xsrv` の両方が同じ
`IdentityFile ~/.ssh/id_ed25519_%l`（`%l` はそのマシンのホスト名）を使う。
鍵を作り直したら、公開鍵を両方に登録し直す。

| 接続先（Host） | 用途 | 登録する場所 |
|---|---|---|
| `github.com` | clone・push | GitHub → Settings → SSH and GPG keys |
| `xsrv`（minorugh.xsrv.jp、ポート10022） | `ssh xsrv`、SFTP、xsrv-backup の rsync、GH・minorugh.com の保険用remote | xserver の `~/.ssh/authorized_keys`（旧鍵の行を削除し、新鍵を追加） |

接続先の指定（ホスト名・ポート・ユーザー・鍵）は config の `Host xsrv` に
一元化する。リポジトリの URL は `xsrv:/home/minorugh/git/...` の別名で書き、
ホスト名を直書きしない（直書きすると config が効かず、鍵が使われない）。
SFTPクライアント（FileZilla等）が config を使わず鍵ファイルを直接指定している
場合は、そちらの設定も確認する。

**注意**

`ssh-setup` は同名の鍵ファイルが既にある場合、新規生成せず既存の鍵を使う。
鍵だけ作り直したいときは、先に `~/.ssh/id_ed25519_<hostname>` と `.pub` を削除する。

## Makefileターゲット一覧

| ターゲット | 内容 |
|---|---|
| `env-restore` | Dropbox上の `env.bundle.gpg` と最新のabookを復元する |
| `ssh-setup` | SSH鍵（空パスフレーズ）をこのマシン専用に新規生成し、config/known_hosts展開・GitHub登録までを案内する（ssh-agent・keychainは使わない） |
| `dotfiles` | `dotfiles` リポジトリをclone |
| `github` | その他の個人リポジトリ群をclone（P1のみ。サブ機では何もしない） |
| `github-dropbox-cleanup` | `GH`・`minorugh.com`・`arch-debian-restore` はclone後 `.git` 以外を削除（実体はDropbox、競合回避。`github` から自動実行。P1のみ） |
| `git` | P1機のみ `git add -A` → 変更があればcommit → push。サブ機は何もしない（Dropbox同期で最新になる） |
| `all` | `dotfiles` → `github` をまとめて実行（`github` はP1のみ） |
| `help` | ターゲット一覧を表示する |

`env-restore`・`ssh-setup` はいずれも対話的な手順を挟むため、`all` には含めず
個別に先に実行する運用にしている。`ssh-setup` は `~/.env_source/.ssh` の内容を
参照するため、必ず `env-restore` の後に実行すること。

GH・minorugh.com の push 先（xserver）を追加する `github-remote-add` は、Makefile から削除した（下記「GitHub private リポジトリの保険運用について」を参照）。

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
自前の Git サーバー（xserver 上の bare リポジトリ）を追加の push 先として
持たせている。GitHub が使えなくなった場合の最終防衛ラインである。

`origin` に `pushurl` を複数登録することで、`git push` 一発で
GitHub と xserver の両方に同時送信される。
`fetch` は GitHub のみに固定し、取得元は単一に保っている。

```bash
git remote -v
# origin  git@github.com:xxx/repo.git (fetch)
# origin  git@github.com:xxx/repo.git (push)
# origin  xsrv:/home/minorugh/git/repo.git (push)
```

この保険は「GitHub の制限・停止」への備えであり、「xserver 自体の喪失」への
備えではない。`GH` の中身は xserver から rsync した動的ファイルを含むため、
xserver を失う場合は Dropbox と GitHub が残りの控えになる。

なお、`xsrv-GH`・`xsrv-minorugh` は xserver の公開サイトのローカルミラー
（`xsrv-backup-smart.sh` が rsync）で、GitHub へ push して世代管理している。
xserver 自体のバックアップなので、xserver へは push しない。

### 注意点

- push 先を追加する `github-remote-add`（と `PRIVATE_HEDGE_REPOS`）は、
  Makefile から削除した。新しいマシンで GH・minorugh.com の xserver への
  push 先を設定するときは、手動で設定する。pushするのはP1機のみ

  ```bash
  git remote set-url --add --push origin git@github.com:minorugh/GH.git
  git remote set-url --add --push origin xsrv:/home/minorugh/git/GH.git
  ```

- `GH`・`minorugh.com` は実体を別ディレクトリ（Dropbox）で管理し、
  `.git`本体だけをここに置く構成のため、clone直後に作業ファイル一式が
  展開されてしまう。これを`.git`のみに整理するのが`github-dropbox-cleanup`
  （`github`ターゲットから自動実行される。P1のみ）

### xserver が最新か確認する

GUI を使わず、手元の HEAD と xserver の HEAD を比べる。

```bash
for r in GH minorugh.com; do
  l=$(git -C ~/src/github.com/minorugh/$r rev-parse HEAD)
  x=$(git ls-remote xsrv:/home/minorugh/git/$r.git HEAD | cut -f1)
  [ "$l" = "$x" ] && echo "OK  $r" || echo "NG  $r local=$l xsrv=$x"
done
```

`NG` なら xserver が遅れている。`git remote -v` で、push 先が `xsrv:` の別名に
なっているか（ホスト名の直書きになっていないか）を確認する。

### GitHub が使えなくなったとき（xserver から復旧）

xserver の bare リポジトリから clone できる。

```bash
git clone xsrv:/home/minorugh/git/GH.git ~/src/github.com/minorugh/GH
```

- 前提: 新しい公開鍵が xserver の `authorized_keys` に入っていること。
  動いているマシンがない場合の登録手段（サーバーパネルなど）は、
  事前に確認しておく
- clone 後は、実体が Dropbox にあるため `.git` 以外を削除する
  （`github-dropbox-cleanup` と同じ整理）
- `origin` は xserver を向く。GitHub の復旧時や移行時に
  `git remote set-url origin ...` で付け替える

## このリポジトリに含まれないもの

秘密鍵・パスフレーズ・`env.bundle.gpg` 本体は含まれません。これらは
すべて `~/Dropbox/arch-debian-restore/` を通じて（Dropbox同期経由で）配布される。

## 補足

`arch-debian-restore` はGH・minorugh.comと同様に「Dropbox実体 + gitdirリンク」
方式（`github-dropbox-cleanup` で `.git` 以外を削除する運用）に揃えてある。
GitHub側への更新は `git` ターゲットで行い、commit と push はP1機だけが行う。
サブ機は何もしない（`pull` も不要。Dropbox同期で最新になる）。サブ機で
`~/src/github.com/minorugh/` に、GH・minorugh.com・arch-debian-restore を
cloneしないこと。

`dotfiles` はDropboxで共有しない通常のリポジトリなので、サブ機でも
`git pull --ff-only` で更新する。サブ機は push しない
（`git remote set-url --push origin no-push`）。
