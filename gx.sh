#!/system/bin/sh

URL="https://github.com/wangkela/wangke/archive/refs/heads/main.zip"
ZIP="/data/adb/modules/wangke/main.zip"
PROGRESS="/data/adb/modules/wangke/progress.txt"
BACKUP="/data/adb/modules/wangke/backup"
TOTAL=253416

# 备份旧模块
mkdir -p "$BACKUP"
cp -a /data/adb/modules/wangke/* "$BACKUP/" 2>/dev/null

# 清理
rm -f "$ZIP"

# 下载
curl -L -o "$ZIP" "$URL" 2>&1 | while read -r line; do
size=$(stat -c%s "$ZIP" 2>/dev/null || echo 0)
percent=$((size * 100 / TOTAL))
echo "$percent" > "$PROGRESS"
done

# 校验
size=$(stat -c%s "$ZIP" 2>/dev/null || echo 0)

if [ "$size" -lt "$TOTAL" ]; then
# ❌ 回滚
cp -a "$BACKUP"/* /data/adb/modules/wangke/ 2>/dev/null
echo "-1" > "$PROGRESS"
exit 1
fi

# 解压
unzip -q "$ZIP_FILE"
mv "$EXTRACT_DIR"/* "$MODULE_DIR/"
mv "$MODULE_DIR/index.html" "$MODULE_DIR/webroot/"
rm -rf "$EXTRACT_DIR" "$ZIP_FILE"
rm -rf "/data/adb/modules/wangke/README.md"
chmod 777 "$MODULE_DIR"/*.sh

echo "100" > "$PROGRESS"