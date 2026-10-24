### Arch & Debian Linux 環境復元用 arch-debian-restore
# 旧 env-import を改名・再設計。GPG本人鍵ceremony・privateリポジトリへの
# 依存をやめ、共通パスフレーズ + Dropbox配布だけで完結する構成にした。
#
# 実行手順:
#   cd ~/Dropbox/arch-debian-restore
#   make env-restore # 対話式（gpgパスフレーズ入力）。env_source・abookを復元
#   make ssh-setup   # 対話式（鍵生成・config/known_hosts展開・GitHub登録を挟むため単独実行）
#   make all         # dotfiles → github（P1 では ~/i.minorugh.com の clone も含む）
#
# 後日（リストア後、安定動作を確認してから）:
#   i.minorugh.com の img/ は空なので、サーバーから戻す: cd ~/i.minorugh.com && make pull
#   必要なもの: rsync、ssh xsrv が通ること（ssh-setup の鍵を Xserver にも登録済みであること）

HOME_SSH := $(HOME)/.ssh
ENV_SOURCE_DIR := $(HOME)/.env_source

# 保険: env-restore / ssh-setup は対話式（パスフレーズ入力・GitHub登録）のため、
# Emacs 内（compile 等）から実行しようとしたら、読み込み時点で止める。
# INSIDE_EMACS は Emacs が子プロセスに設定する環境変数。止まる場合はレシピを
# 1行も実行しないので、鍵の生成などは起きない。他のターゲット（git 等）は
# Emacs から実行しても影響を受けない。
$(if $(and $(INSIDE_EMACS),$(filter env-restore ssh-setup,$(MAKECMDGOALS))),$(error env-restore / ssh-setup は対話式です。ターミナルから実行してください))

# ifeq は読み込み時に評価されるため、HOSTNAME は ifeq より前に定義しておくこと。
# (後ろに置くと、環境変数として export されていない場合 P1 でも else 側になる)
HOSTNAME := $(shell hostname)

.DEFAULT_GOAL := help
.PHONY: all help env-restore ssh-setup dotfiles github github-dropbox-cleanup git

help: ## ターゲット一覧を表示する
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-24s\033[0m %s\n", $$1, $$2}'

all: dotfiles github ## dotfiles → github をまとめて実行（env-restore・ssh-setupは対話式のため個別実行）

########################################################
## env-restore（旧env-import。abook-restoreを統合）
########################################################
env-restore: ## Dropbox上のenv.bundle.gpgを復元する（パスフレーズを聞かれます）
	gpg -d ~/Dropbox/backup/env/env.bundle.gpg > /tmp/env.bundle
	git clone /tmp/env.bundle ~/.env_source
	rm /tmp/env.bundle
	@echo "##> env_source を復元しました（abookも含む）。"

########################################################
## SSH鍵（マシンごとに新規生成。他機の鍵は流用しない）
########################################################
# 注意: ここで案内するのは GitHub への公開鍵登録だけ。
# Xserver（ssh xsrv。i.minorugh.com の make pull などで使う）にも、同じ公開鍵を
# サーバーパネルの SSH 設定で別途登録しないと接続できない。登録後は ssh xsrv true で確認する。
ssh-setup: ## SSH鍵（空パスフレーズ）を新規生成し、config/known_hosts展開・GitHub登録までを案内する
	command -v pacman >/dev/null && ( pacman -Q xclip &>/dev/null || sudo pacman -S --needed --noconfirm xclip ) || \
	( dpkg -s xclip &>/dev/null || sudo apt install -y xclip )
	mkdir -p $(HOME_SSH)
	test -f $(HOME_SSH)/id_ed25519_$$(hostname) || \
		ssh-keygen -t ed25519 -N "" -C "$$(hostname)-$$(date +%Y%m%d)" \
			-f $(HOME_SSH)/id_ed25519_$$(hostname)
	for item in config known_hosts; do \
		ln -vsf $(ENV_SOURCE_DIR)/.ssh/$$item $(HOME_SSH)/$$item; \
	done
	cat $(HOME_SSH)/id_ed25519_$$(hostname).pub | xclip -selection clipboard
	xdg-open https://github.com/settings/ssh/new 2>/dev/null &
	@echo ""
	@echo "1) 公開鍵をクリップボードにコピーしました。開いたページに貼り付けて登録してください"
	@echo "   （Title は id_ed25519_$$(hostname) にします）"
	@echo "   （念のため下にも表示します）"
	@echo "----------------------------------------------------------"
	@cat $(HOME_SSH)/id_ed25519_$$(hostname).pub
	@echo "----------------------------------------------------------"
	@echo "2) 登録できたら次を実行してください"
	@echo "   ssh -T git@github.com"
	@echo "3) Xserver にも、同じ公開鍵をサーバーパネルの SSH 設定で登録してください（make pull 等で必要）"
	@echo "   登録後の確認: ssh xsrv true"

########################################################
## dotfiles
########################################################
dotfiles: ## dotfilesリポジトリをclone
	mkdir -p ${HOME}/src/github.com/minorugh
	cd ${HOME}/src/github.com/minorugh && \
	git clone git@github.com:minorugh/dotfiles.git

########################################################
## github（その他リポジトリ群。dotfiles/Makefileから移植）
########################################################
# 実体が ~/Dropbox 側にあり、ここには .git 本体のみを置くリポジトリ
DROPBOX_GITDIR_REPOS := GH minorugh.com arch-debian-restore

github: ## GitHubリポジトリ群をclone（~/i.minorugh.com ~/cl を含む。P1のみ）
ifeq ($(HOSTNAME),P1)
	mkdir -p ${HOME}/src/github.com/minorugh
	cd ${HOME}/src/github.com/minorugh; \
	git clone git@github.com:minorugh/GH.git; \
	git clone git@github.com:minorugh/minorugh.com.git; \
	git clone git@github.com:minorugh/arch-debian-restore.git; \
	git clone git@github.com:minorugh/minorugh.github.io.git; \
	git clone git@github.com:minorugh/upsftp.git; \
	git clone git@github.com:minorugh/git-peek.git; \
	git clone git@github.com:minorugh/dashboard-widget-extensions.git; \
	git clone git@github.com:minorugh/tempbuf.git; \
	git clone git@github.com:minorugh/deepl-translate.git; \
	git clone git@github.com:minorugh/xsrv-GH.git; \
	git clone git@github.com:minorugh/xsrv-minorugh.git
	$(MAKE) -s github-dropbox-cleanup
	cd ${HOME}/; \
	git clone git@github.com:minorugh/i.minorugh.com.git; \
	git clone git@github.com:minorugh/cl.git; \
else
	@echo "$(HOSTNAME): サブ機では何もしません"
endif

github-dropbox-cleanup: ## clone後に.git以外を削除（P1のみ。実体はDropbox、競合回避）
ifeq ($(HOSTNAME),P1)
	@for repo in $(DROPBOX_GITDIR_REPOS); do \
		dir=${HOME}/src/github.com/minorugh/$$repo; \
		if [ -d "$$dir/.git" ]; then \
			find "$$dir" -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +; \
			echo "✓ cleaned: $$dir (.git のみ残しました)"; \
		else \
			echo "⚠ skip: $$dir/.git が見つかりません（clone失敗の可能性）"; \
		fi; \
	done
else
	@echo "$(HOSTNAME): サブ機では何もしません"
endif

# P1 (main): commit + push / others (sub): 何もしない（Dropbox同期で最新になる）
git: ## P1のみ commit + push（サブ機は何もしない）
ifeq ($(HOSTNAME),P1)
	git add -A
	git diff --cached --quiet || git commit -m "auto: $$(date '+%Y-%m-%d %H:%M:%S')"
	git push
else
	@echo "$(HOSTNAME): サブ機では何もしません（Dropbox同期で最新になります）"
endif

# ------------------------------------------------------------
# [Read-only] This file opens in read-only mode automatically.
# Toggle editable: C-c C-e  or  qq
# ------------------------------------------------------------
# Local Variables:
# buffer-read-only: t
# End:
