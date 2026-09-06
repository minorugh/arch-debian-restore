### Arch Linux 環境復元用 arch-restore
# 旧 env-import を改名・再設計。GPG本人鍵ceremony・privateリポジトリへの
# 依存をやめ、共通パスフレーズ + Dropbox配布だけで完結する構成にした。
#
# 実行手順:
#   cd ~/Dropbox/arch-restore
#   make ssh-setup   # 対話式（GitHub登録を挟むため単独実行）
#   make all         # env-restore → dotfiles → github

HOSTNAME := $(shell hostname)
HOME_SSH := $(HOME)/.ssh

.DEFAULT_GOAL := help
.PHONY: all help env-restore ssh-setup dotfiles github github-dropbox-cleanup

help: ## ターゲット一覧を表示する
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-24s\033[0m %s\n", $$1, $$2}'

all: env-restore dotfiles github ## env-restore → dotfiles → github をまとめて実行

########################################################
## env-restore（旧env-import。abook-restoreを統合）
########################################################
env-restore: ## Dropbox上のenv.bundle.gpgとabookを復元する（パスフレーズを聞かれます）
	gpg -d ~/Dropbox/arch-restore/env.bundle.gpg > /tmp/env.bundle
	git clone /tmp/env.bundle ~/.env_source
	rm /tmp/env.bundle
	mkdir -p ~/.abook
	gpg --yes -d -o ~/.abook/addressbook $$(ls -t ~/Dropbox/backup/abook/addressbook_*.gpg | head -1)
	@echo "##> env_source / abook を復元しました。"

########################################################
## SSH鍵（マシンごとに新規生成。他機の鍵は流用しない）
########################################################
ssh-setup: ##! SSH鍵を新規生成し、GitHub登録・keychain設定までを案内する
	pacman -Q keychain &>/dev/null || sudo pacman -S --needed --noconfirm keychain xclip
	mkdir -p $(HOME_SSH)
	test -f $(HOME_SSH)/id_ed25519_$$(hostname) || \
		ssh-keygen -t ed25519 -N "" -C "$$(hostname)-$$(date +%Y%m%d)" \
			-f $(HOME_SSH)/id_ed25519_$$(hostname)
	cat $(HOME_SSH)/id_ed25519_$$(hostname).pub | xclip -selection clipboard
	xdg-open https://github.com/settings/ssh/new 2>/dev/null &
	@echo ""
	@echo "1) 公開鍵をクリップボードにコピーしました。開いたページに貼り付けて登録してください"
	@echo "   （念のため下にも表示します）"
	@echo "----------------------------------------------------------"
	@cat $(HOME_SSH)/id_ed25519_$$(hostname).pub
	@echo "----------------------------------------------------------"
	@echo "2) 登録できたら ~/.ssh/config に以下を追記してください"
	@echo "   （env-restore で復元したconfigテンプレートに含まれていれば不要）"
	@echo ""
	@echo "Host github.com"
	@echo "    HostName github.com"
	@echo "    User git"
	@echo "    IdentityFile ~/.ssh/id_ed25519_$$(hostname)"
	@echo "    IdentitiesOnly yes"
	@echo ""
	@echo "3) 追記できたら次を実行してください"
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
DROPBOX_GITDIR_REPOS := GH minorugh.com

github: ## GitHubリポジトリ群をclone
	mkdir -p ${HOME}/src/github.com/minorugh
	cd ${HOME}/src/github.com/minorugh; \
	git clone git@github.com:minorugh/GH.git; \
	git clone git@github.com:minorugh/minorugh.com.git; \
	git clone git@github.com:minorugh/minorugh.github.io.git; \
	git clone git@github.com:minorugh/upsftp.git; \
	git clone git@github.com:minorugh/git-peek.git; \
	git clone git@github.com:minorugh/dashboard-widget-extensions.git; \
	git clone git@github.com:minorugh/tempbuf.git; \
	git clone git@github.com:minorugh/deepl-translate.git; \
	git clone git@github.com:minorugh/xsrv-GH.git; \
	git clone git@github.com:minorugh/xsrv-minorugh.git
	$(MAKE) -s github-dropbox-cleanup
# Phase 4（arch-restoreのpublic保険化）着手後、以下を有効化する:
# 	git clone git@github.com:minorugh/arch-restore.git
# と DROPBOX_GITDIR_REPOS に arch-restore を追加し、github-dropbox-cleanup
# （gitdirリンク生成込み・dotfiles/Makefileから移植予定）を実行する。
# 現時点ではpublicリポジトリ自体が未作成のため無効化している。

github-dropbox-cleanup: ## GH/minorugh.com はclone後.git以外を削除（実体はDropbox、競合回避）
	@for repo in $(DROPBOX_GITDIR_REPOS); do \
		dir=${HOME}/src/github.com/minorugh/$$repo; \
		if [ -d "$$dir/.git" ]; then \
			find "$$dir" -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +; \
			echo "✓ cleaned: $$dir (.git のみ残しました)"; \
		else \
			echo "⚠ skip: $$dir/.git が見つかりません（clone失敗の可能性）"; \
		fi; \
	done

# P1 (main): commit + push / others (sub): pull --rebase only
git: ## git push / pull
	git add -A
	git diff --cached --quiet || git commit -m "auto: $$(date '+%Y-%m-%d %H:%M:%S')"
ifeq ($(HOSTNAME),P1)
	git push
else
	@echo "$(HOSTNAME): サブ機からはpushしません"
	git pull --rebase
endif

# ------------------------------------------------------------
# [Read-only] This file opens in read-only mode automatically.
# Toggle editable: C-c C-e  or  qq
# ------------------------------------------------------------
# Local Variables:
# buffer-read-only: t
# End:

