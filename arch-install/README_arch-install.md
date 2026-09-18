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

### 5. Arch固有の環境構築

```bash
cd arch-install
make base         # 基本パッケージ・日本語ロケール一括導入
make sudo-setup   # wheelグループのsudo有効化
make yay          # AURヘルパー（導入済みならスキップ）
make aur          # fcitx5-mozc-ut・emacs-mozc・cmigemo・arc-gtk-theme・nkf 等を導入
make zsh-default  # ログインシェルをzshに
```

（`dropbox` はステップ3で手動導入済みだが `make aur` のAUR_PACKAGESにも
含まれている。`--needed` のため再実行しても無害）

### 6. Emacs自家ビルド（任意・時間がかかります）

```bash
make emacs-stable
```

### 7. dotfiles展開

```bash
make init
```

`.gitconfig`の`user.name`/`user.email`は展開後に書き換えてください。

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
- `.autostart.sh`（Debian機ではDropbox経由の復元・keychain自動化等、共有前提の設計。書き直しが必要）
- neomutt関連
- 自作elispパッケージ群（git-peek, gcal-dashboard, dashboard-widget-extensions等。
  個別に独立リポジトリとして公開済みのため、必要になった時点で個別にclone）

## 既知の懸案

- pacman版emacsとの共存は avoid 済み（`base`にemacsを含めていない）。
  Let's note側での自家ビルド動作確認は次回セッションで実施
- keychainのエージェントが原因不明で時々死ぬ問題が過去にあった（未解決、再発時は
  `keychain --stop all && rm -rf ~/.ssh/agent ~/.keychain && keychain <鍵>` でリセット）
