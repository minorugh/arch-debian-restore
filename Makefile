### Arch & Debian Linux 環境復元用 arch-debian-restore
# 旧 env-import を改名・再設計。GPG本人鍵ceremony・privateリポジトリへの
# 依存をやめ、共通パスフレーズ + Dropbox配布だけで完結する構成にした。
#
# 実行手順:
#   cd ~/Dropbox/arch-debian-restore
#   make env-restore # 対話式（gpgパスフレーズ入力）。env_source・abookを復元
#   make ssh-setup   # 対話式（鍵生成・config/known_hosts展開・GitHub登録を挟むため単独実行）
#   make all         # dotfiles → github

HOME_SSH := $(HOME)/.ssh
ENV_SOURCE_DIR := $(HOME)/.env_source

# ifeq は読み込み時に評価されるため、HOSTNAME は ifeq より前に定義しておくこと。
# (後ろに置くと、環境変数として export されていない場合 P1 でも else 側になる)
HOSTNAME := $(shell hostname)

.DEFAULT_GOAL := help
.PHONY: all help env-restore ssh-setup dotfiles github github-dropbox-cleanup

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
ssh-setup: ##! SSH鍵（空パスフレーズ）を新規生成し、config/known_hosts展開・GitHub登録までを案内する
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
	@echo "   （念のため下にも表示します）"
	@echo "----------------------------------------------------------"
	@cat $(HOME_SSH)/id_ed25519_$$(hostname).pub
	@echo "----------------------------------------------------------"
	@echo "2) 登録できたら次を実行してください"
	@echo "   ssh -T git@github.com"

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

github: ## GitHubリポジトリ群をclone（P1のみ）
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
