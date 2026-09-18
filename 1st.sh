#!/bin/sh
# 0段階ブートストラップ
#
# Dropboxクライアントは手動インストール・同期完了を待ってから、
# ~/Dropbox/arch-debian-restore/1st.sh をこのマシン上で実行する想定。
#
# Arch(EndeavourOS): yay/git/make/firefoxが標準搭載のため、このスクリプトは
#   基本的に何もしない（確認のみ）
# Debian: git/makeが未導入のため導入する
#
# 使い方: cd ~/Dropbox/arch-debian-restore && bash 1st.sh

set -eu

if command -v yay >/dev/null 2>&1; then
	echo "== Arch(EndeavourOS)検出 =="
	echo "✓ yay・git・make は標準搭載のため、導入すべきものはありません"

elif command -v apt >/dev/null 2>&1; then
	echo "== Debian検出: git・make の導入 =="
	sudo apt update
	sudo apt install -y git make
	echo "✓ git・make の導入完了"

else
	echo "✗ yay/apt どちらも見つかりませんでした。対応外の環境です。" >&2
	exit 1
fi

echo ""
echo "== 次のステップ =="
echo "  make env-restore"
echo "  make ssh-setup"
echo "  make all"
