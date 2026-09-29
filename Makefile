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

.DEFAULT_GOAL := help
.PHONY: all help env-restore ssh-setup dotfiles github github-dropbox-cleanup github-remote-add

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
ssh-setup: ##! SSH鍵を新規生成し、config/known_hosts展開・GitHub登録・keychain設定までを案内する
	command -v pacman >/dev/null && ( pacman -Q keychain &>/dev/null || sudo pacman -S --needed --noconfirm keychain xclip ) || \
	( dpkg -s keychain xclip &>/dev/null || sudo apt install -y keychain xclip )
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
	@echo "   keychain ~/.ssh/id_ed25519_$$(hostname) && ssh -T git@github.com"

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

github: ## GitHubリポジトリ群をclone
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

github-dropbox-cleanup: ## GH/minorugh.com/arch-debian-restore はclone後.git以外を削除（実体はDropbox、競合回避）
	@for repo in $(DROPBOX_GITDIR_REPOS); do \
		dir=${HOME}/src/github.com/minorugh/$$repo; \
		if [ -d "$$dir/.git" ]; then \
			find "$$dir" -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +; \
			echo "✓ cleaned: $$dir (.git のみ残しました)"; \
		else \
			echo "⚠ skip: $$dir/.git が見つかりません（clone失敗の可能性）"; \
		fi; \
	done

# GitHub private リポジトリの制限リスクに備え、xserver(bare repo)+Giteaを保険として追加するリポジトリ
# ( xserverはbare repoのためGUIを持たない → Giteaがその代役 )
# 2026.09.16 dotfiles/Makefileから移植（個人のリポジトリ群管理という関心事をこちらに一本化）
PRIVATE_HEDGE_REPOS := GH minorugh.com

github-remote-add: ##! GH/minorugh.com に xserver + Gitea pushurl を追加（Docker/Gitea起動後に手動実行）
	@read -p "Gitea は起動していますか？ xserver への疎通は確認済みですか？ [y/N]: " ans; \
	[ "$$ans" = "y" ] || { echo "中止しました。"; exit 1; }
	@for repo in $(PRIVATE_HEDGE_REPOS); do \
		dir=${HOME}/src/github.com/minorugh/$$repo; \
		if git -C "$$dir" remote get-url --push --all origin | grep -q "xsrv"; then \
			echo "⚠ skip: $$repo は既に設定済みです"; \
		else \
			git -C "$$dir" remote set-url --add --push origin xsrv:/home/minorugh/git/$$repo.git; \
			git -C "$$dir" remote set-url --add --push origin http://localhost:3000/minoru/$$repo.git; \
			echo "✓ pushurl added: $$repo (xserver + Gitea)"; \
		fi; \
	done
# git clone 直後は GitHub のみが remote。このターゲットで xserver・Gitea を pushurl に追加する。
# push 時は GitHub・xserver・Gitea の3箇所へ送信される（fetch は GitHub のみ）

# P1 (main): commit + push / others (sub): 何もしない（Dropbox同期で最新になる）
HOSTNAME := $(shell hostname)

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
