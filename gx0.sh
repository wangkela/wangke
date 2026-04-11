#!/system/bin/sh

# ===== 路径配置 =====
MODULE_PROP="/data/adb/modules/wangke/module.prop"
VERSION_FILE="/data/adb/modules/wangke/wangke_version.txt"
GX_FILE="/data/adb/modules/wangke/gx"
URL="https://raw.githubusercontent.com/wangkela/wangke/refs/heads/main/wangke_version.txt"

# ===== 读取 module.prop 版本 =====
module_version=$(grep '^version=' "$MODULE_PROP" 2>/dev/null | cut -d'=' -f2)

# 判空
if [ -z "$module_version" ]; then
echo "[wangke] module.prop 中未找到 version"
exit 1
fi

curl --connect-timeout 5 --max-time 5 -fsSL -o "$VERSION_FILE" "$URL" || {
echo "[wangke] 下载超时或失败 (5秒)"
rm -f "$VERSION_FILE"
exit 1
}

# ===== 读取并校验本地版本号 =====
local_version=$(cat "$VERSION_FILE" 2>/dev/null)

# 判空 & 判大小（防止空文件）
if [ -z "$local_version" ] || [ ! -s "$VERSION_FILE" ]; then
echo "[wangke] 版本文件内容为空"
rm -f "$VERSION_FILE"
exit 1
fi

# 去除换行符和空格（防止 Windows 格式问题）
module_version=$(echo "$module_version" | tr -d '\r\n ')
local_version=$(echo "$local_version" | tr -d '\r\n ')

# ===== 版本对比 =====
if [ "$module_version" = "$local_version" ]; then
touch "$GX_FILE"
echo "16.0" > "$GX_FILE"
rm -f "$VERSION_FILE"
exit 0
else
rm -f "$GX_FILE"
rm -f "$VERSION_FILE"
exit 1
fi
