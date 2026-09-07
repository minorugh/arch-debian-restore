#!/bin/bash
set -e

# 保存先ディレクトリの定義
ISO_DIR="$HOME/tmp/endeavouros"
mkdir -p "${ISO_DIR}"

# 最新のISOファイル名とURLの定義（miraa.jp ミラー、日本国内の公式EndeavourOSミラー）
ISO_NAME="EndeavourOS_Titan-Nova-2026.08.15.iso"
SUM_NAME="EndeavourOS_Titan-Nova-2026.08.15.iso.sha512sum"
BASE_URL="https://www.miraa.jp/endeavouros/iso"

# 既存のISOファイルを検索
mapfile -t iso_files < <(find "${ISO_DIR}" -maxdepth 1 -name "${ISO_NAME}" | sort)

if [ "${#iso_files[@]}" -eq 0 ]; then
  echo "EndeavourOS の ISO が見つからないため、ダウンロードします（数分かかります）。"
  cd "${ISO_DIR}"
  wget "${BASE_URL}/${ISO_NAME}"
  wget "${BASE_URL}/${SUM_NAME}"
  
  # sha512によるファイルの完全性チェック
  echo "ダウンロードファイルのチェックサムを検証中..."
  if ! sha512sum -c "${SUM_NAME}"; then
    echo "検証に失敗しました。ISOが壊れている可能性があります。"
    echo "${ISO_DIR}/${ISO_NAME} を削除してから、もう一度実行してください。"
    exit 1
  fi
  ISO_PATH="${ISO_DIR}/${ISO_NAME}"
else
  ISO_PATH="${iso_files}"
  echo "既存の ISO を使用します: ${ISO_PATH}"
fi

# 1本だけ挿さっているUSBメモリを自動検出
mapfile -t usb_disks < <(lsblk -d -b -o NAME,SIZE,MODEL,TRAN -n | awk '{
  tran = $NF
  size = $2
  if (tran == "usb" && size + 0 > 0) {
    name = $1
    model = ""
    for (i = 3; i < NF; i++) {
      model = (model == "") ? $i : model " " $i
    }
    print name "|" size "|" model
  }
}')

usb_count=${#usb_disks[@]}

if [ "$usb_count" -eq 0 ]; then
  echo "USBが検出されませんでした。USBメモリが挿さっているか確認してください。"
  exit 1
fi

if [ "$usb_count" -ge 2 ]; then
  echo "USBが複数検出されました。安全のため処理を中止します。"
  echo "他のUSB機器を外し、書き込み先のUSBだけを挿した状態でやり直してください。"
  printf '検出されたUSB:\n'
  for entry in "${usb_disks[@]}"; do
    IFS='|' read -r name size model <<< "$entry"
    human_size=$(numfmt --to=iec --suffix=B "${size}")
    printf '  /dev/%s  %s  %s\n' "$name" "$human_size" "$model"
  done
  exit 1
fi

IFS='|' read -r name size model <<< "${usb_disks}"
target="/dev/${name}"
human_size=$(numfmt --to=iec --suffix=B "${size}")

echo "検出されたUSB: ${target}  サイズ: ${human_size}  モデル: ${model}"
echo "このUSBの中身は【古いデータも含めて全て綺麗に上書き消去】され、動作チェック用Liveメディアになります。"
read -r -p "このUSBに書き込みますか？ [y/N]: " answer

if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
  echo "中止しました。何も変更していません。"
  exit 1
fi

mapfile -t mounted_parts < <(lsblk -ln -o MOUNTPOINT "${target}" | grep -v '^$')
if [ "${#mounted_parts[@]}" -gt 0 ]; then
  echo "自動マウントされているパーティションを取り外します..."
  sudo umount "${target}"?* 2>/dev/null || true
fi

echo "上書き書き込み中です。完了まで数十秒〜数分かかります。途中で操作しないでください..."
sudo dd if="${ISO_PATH}" of="${target}" bs=4M status=progress conv=fsync
echo "書き込みが完了しました。最強のThinkPad目利き用Live USBの完成です！"
