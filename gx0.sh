#!/system/bin/sh

MODULE_PROP="/data/adb/modules/wangke/module.prop"
VERSION_FILE="/data/adb/modules/wangke/wangke_version.txt"
GX_FILE="/data/adb/modules/wangke/gx"

curl -o wangke_version.txt https://raw.githubusercontent.com/wangkela/wangke/refs/heads/main/wangke_version.txt

# 读取 module.prop 中的 version
module_version=$(grep '^version=' "$MODULE_PROP" | cut -d'=' -f2)

# 读取 wangke_version.txt 中的版本号
local_version=$(cat "$VERSION_FILE" 2>/dev/null)

# 判断是否为空
if [ -z "$module_version" ] || [ -z "$local_version" ]; then
exit 1
fi

# 去除换行和空格
module_version=$(echo "$module_version" | tr -d '\r\n ')
local_version=$(echo "$local_version" | tr -d '\r\n ')

# 对比
if [ "$module_version" = "$local_version" ]; then
touch "$GX_FILE"
rm -rf "$VERSION_FILE"
exit 0
else
rm -rf "$GX_FILE"
rm -rf "$VERSION_FILE"
exit 1
fi

