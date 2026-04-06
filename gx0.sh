#!/system/bin/sh

MODULE_PROP="/data/adb/modules/wangke/module.prop"
VERSION_FILE="/data/adb/modules/wangke/wangke_version.txt"
GX_FILE="/data/adb/modules/wangke/gx"
URL="https://raw.githubusercontent.com/wangkela/wangke/refs/heads/main/wangke_version.txt"

# 读取 module.prop 中的 version
module_version=$(grep '^version=' "$MODULE_PROP" | cut -d'=' -f2)

# 下载版本号文件（必须成功）
curl -L --connect-timeout 10 --retry 2 -o "$VERSION_FILE" "$URL"
if [ $? -ne 0 ]; then
echo "[wangke] 下载版本文件失败"
rm -f "$VERSION_FILE"
exit 1
fi

# 读取本地版本号
local_version=$(cat "$VERSION_FILE" 2>/dev/null)

# 判空
if [ -z "$module_version" ] || [ -z "$local_version" ]; then
echo "[wangke] 版本号为空"
rm -f "$VERSION_FILE"
exit 1
fi

# 去除换行和空格
module_version=$(echo "$module_version" | tr -d '\r\n ')
local_version=$(echo "$local_version" | tr -d '\r\n ')

# 对比
if [ "$module_version" = "$local_version" ]; then
touch "$GX_FILE"
echo "14.0" > "$GX_FILE"
rm -f "$VERSION_FILE"
exit 0
else
rm -f "$GX_FILE"
rm -f "$VERSION_FILE"
exit 1
fi
