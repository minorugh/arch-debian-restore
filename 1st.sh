#!/bin/sh
# 0段階ブートストラップ
#
# Dropboxクライアントは手動インストール・同期完了を待ってから、
# ~/Dropbox/arch-debian-restore/1st.sh をこのマシン上で実行する想定。
#
# Arch(EndeavourOS): yay/git/make/firefoxが標準搭載のため、基本的に確認のみ。
#   rsync だけは、なければ導入する（make i-minorugh が使う）
# Debian: git/make/rsyncが未導入のため導入する
#
# 使い方: cd ~/Dropbox/arch-debian-restore && bash 1st.sh

set -eu

if command -v yay >/dev/null 2>&1; then
	echo "== Arch(EndeavourOS)検出 =="
	echo "✓ yay・git・make は標準搭載のため、導入すべきものはありません"
	if command -v rsync >/dev/null 2>&1; then
		echo "✓ rsync は導入済みです"
	else
		echo "== rsync の導入 =="
		sudo pacman -S --needed --noconfirm rsync
		echo "✓ rsync の導入完了"
	fi

elif command -v apt >/dev/null 2>&1; then
	echo "== Debian検出: git・make・rsync の導入 =="
	sudo apt update
	sudo apt install -y git make rsync
	echo "✓ git・make・rsync の導入完了"

else
	echo "✗ yay/apt どちらも見つかりませんでした。対応外の環境です。" >&2
	exit 1
fi

echo ""
echo "== 次のステップ =="
echo "  make env-restore"
echo "  make ssh-setup"
echo "  make all"
