#!/system/bin/sh

DOWNLOAD_URL="https://github.com/wangkela/wangke/archive/refs/heads/main.zip"
ZIP_FILE="/data/adb/modules/wangke/main.zip"
EXTRACT_DIR="wangke-main"
MODULE_DIR="/data/adb/modules/wangke"
TOTAL_SIZE=253416

cd "$MODULE_DIR" || exit 1

# 清理
rm -f "$ZIP_FILE"
rm -rf "$EXTRACT_DIR"

# 下载（前台，不解析进度）
curl -L -o "$ZIP_FILE" "$DOWNLOAD_URL"

if [ ! -f "$ZIP_FILE" ]; then
exit 1
fi

# 解压
unzip -q "$ZIP_FILE"
mv "$EXTRACT_DIR"/* "$MODULE_DIR/"
mv "$MODULE_DIR/index.html" "$MODULE_DIR/webroot/"
rm -rf "$EXTRACT_DIR" "$ZIP_FILE"
rm -rf "/data/adb/modules/wangke/README.md"
chmod 777 "$MODULE_DIR"/*.sh