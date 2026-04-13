#!/system/bin/sh

DOWNLOAD_URL="https://github.com/wangkela/wangke/archive/refs/heads/main.zip"
ZIP_FILE="/data/adb/modules/wangke/main.zip"
EXTRACT_DIR="wangke-main"
MODULE_DIR="/data/adb/modules/wangke"
TOTAL_SIZE=255795

cd "$MODULE_DIR" || exit 1
rm -f "$ZIP_FILE"
rm -rf "$EXTRACT_DIR"
curl -L -o "$ZIP_FILE" "$DOWNLOAD_URL"
unzip -q "$ZIP_FILE"
mv "$EXTRACT_DIR"/* "$MODULE_DIR/"
mv "$MODULE_DIR/index.html" "$MODULE_DIR/webroot/"
rm -rf "$EXTRACT_DIR" "$ZIP_FILE"
rm -rf "/data/adb/modules/wangke/README.md"
rm -rf "/data/adb/modules/wangke/wangke_version.txt"
chmod 777 "$MODULE_DIR"/*.sh
date +%s > /data/adb/modules/wangke/.update_success
/data/adb/modules/wangke/start.sh