# arch-install

Let's note CF-LX3 用の Arch Linux 環境構築（OS固有部分）。
Debian機（P1メイン / X250サブ）とは完全に独立した**単独機**として構築します。
dotfiles・SSH鍵・GPG秘密鍵は一切共有しません。

このリポジトリは単独では存在せず、`arch-debian-restore` のサブディレクトリ
（`~/Dropbox/arch-debian-restore/arch-install/`）として、Dropbox同期経由で
配布されます。個別に `git clone` する必要はありません。

共通ブートストラップ（env-restore・ssh-setup・dotfiles/githubのclone）は
`arch-debian-restore/Makefile` 側の役割です。このMakefileは
パッケージ導入・Emacs自家ビルド・dotfiles展開・bin/スクリプトのリンクなど、
**OS固有の構築部分のみ**を担当します。

---

## 構成

```
arch-install/
├── README.md           このファイル
├── Makefile             Arch環境構築本体
└── docs/                 作業記録・引き継ぎメモ
    ├── Arch_Linux_インストール作業記録.md
    └── arch-standalone-handover.md
```

Live USB作成は `arch-debian-restore/arch-live-usb/`（このリポジトリの外）を参照。

---

## 使い方

### 1. Live USB作成・起動（別マシンで実施）

```bash
cd ~/Dropbox/backup/make-live-usb/arch-live-usb
bash make-live-usb.sh
```

EndeavourOSのISOを自動ダウンロード・検証したうえで、USBを自動検出して
書き込みます。CF-LX3にUSBを挿し、[F12]でBoot Menuを開いて起動します。
詳細は `~/Dropbox/backup/make-live-usb/arch-live-usb/README_arch-live-usb.md` を参照。

### 2. インストール（Calamares）

Live環境のデスクトップからCalamares（GUIインストーラー）でインストールします。
EndeavourOSはyay・git・make・base-devel・firefoxが標準搭載のため、この時点で
既に揃っています。

### 3. Dropboxクライアントの手動インストール

EndeavourOSはyay・git・make・base-devel・firefoxが標準搭載のため、ここで
自動化すべきものは特に無い。Dropboxクライアントのみ手動でインストールし、
ログイン後、同期完了を待つ
（→ `~/Dropbox/arch-debian-restore/` が出現し、`arch-install`もこの中に含まれる）。

同期完了後、`~/Dropbox/arch-debian-restore/1st.sh` を実行する（内容は
Debian向けの git・make 導入のみで、Archでは基本何もしない）。

```bash
cd ~/Dropbox/arch-debian-restore
bash 1st.sh
```

### 4. 共通ブートストラップ

```bash
cd ~/Dropbox/arch-debian-restore
make env-restore   # 対話式。env_source・abookを復元
make ssh-setup     # 対話式。SSH鍵新規生成・GitHub登録
make all           # dotfiles → github
```

`github` はP1のみのターゲットで、Arch（サブ機）では何もしない。

### 5. Arch固有の環境構築

```bash
cd arch-install
make base         # 基本パッケージ・日本語ロケール・keyring（gnome-keyring・seahorse）一括導入
make sudo-setup   # wheelグループのsudo有効化
make yay          # AURヘルパー（導入済みならスキップ）
make aur          # fcitx5-mozc-ut・emacs-mozc・cmigemo・arc-gtk-theme・nkf 等を導入
make zsh-default  # ログインシェルをzshに
```

（`dropbox` はステップ3で手動導入済みだが `make aur` のAUR_PACKAGESにも
含まれている。`--needed` のため再実行しても無害）

### 5-2. keyringの初回設定

`make base` で gnome-keyring・seahorse・libsecret が入る。Chromium を初めて
起動すると、キーリングのパスワードのダイアログが出るので、
**何も入力せずに Enter** を押す（空パスワードの `Default_Keyring` ができる）。
以降は、自動ログインでも聞かれない（Debian機と同じ動作）。この操作は自動化できない。

- Debian機とキーリングは共用しない。Arch は独立して持つ
- PAMの `pam_gnome_keyring` の行は削除しない（自動ログインでは効かないが、害もない）
- ssh には関係しない（agent は使わない）

### 6. Emacs自家ビルド（任意・時間がかかります）

```bash
make emacs-stable
```

### 7. dotfiles展開

```bash
make init
```

`.gitconfig`の`user.name`/`user.email`は展開後に書き換えてください。

Arch はサブ機なので、dotfiles は pull だけを行い（`git pull --ff-only`）、push しない
（`git remote set-url --push origin no-push`）。

---

## sudoが効かないとき

Calamaresでsudo権限付きユーザーを作成したはずでも、まれに`wheel`グループの
有効化が反映されていないことがあります。

```bash
sudo -v
```

これが通らない場合、rootでログインし直して以下を確認してください。

```bash
groups ${USER}                      # wheelに入っているか確認
usermod -aG wheel ${USER}           # 入っていなければ追加
EDITOR=nano visudo                  # %wheel ALL=(ALL:ALL) ALL の行頭#を確認・削除
```

---

## 段階的に導入するもの（今は入れない）

「裸の安定構築」を先に固めてから、以下は状況を見ながら個別に判断して追加します。
詳細は `docs/arch-standalone-handover.md` を参照。

- `.xprofile` / `.Xmodmap`（キーボード・X周りの調整。CF-LX3実機のkeycode要確認）
- `.autostart.sh`（Debian機ではDropbox経由のkeyring復元・Mozcのコピー等、共有前提の設計。Archではkeyringを共有しないため書き直しが必要。keychainの起動ブロックはコメントアウト済み）
- neomutt関連
- 自作elispパッケージ群（git-peek, gcal-dashboard, dashboard-widget-extensions等。
  個別に独立リポジトリとして公開済みのため、必要になった時点で個別にclone）

## 既知の懸案

- pacman版emacsとの共存は avoid 済み（`base`にemacsを含めていない）。
  Let's note側での自家ビルド動作確認は次回セッションで実施
- keychainは全廃した（2026-10）。sshはagentを使わず、`~/.ssh/config` の
  `IdentityFile`（空パスフレーズのマシン専用鍵）で直接接続する。過去にあった
  「keychainのエージェントが時々死ぬ問題」は、keychain自体がないため該当しない
