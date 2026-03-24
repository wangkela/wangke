#!/bin/sh

# 设置权限
chmod 777 "/data/adb/modules/wangke/wangke.sh"
chmod 777 "/data/adb/modules/wangke/action.sh"
chmod 777 "/data/adb/modules/wangke/wangkela.sh"

MODDIR="/data/adb/modules/wangke"
UPDATE_SCRIPT="$MODDIR/gx.sh"
CONFIG_FILE="/data/adb/亡客/pz.ini"
TEMP_KEY_EVENT="/tmp/wangke_keyevent.tmp"

# 清理临时文件
cleanup_temp() {
rm -f "$TEMP_KEY_EVENT" 2>/dev/null
pkill -f "getevent.*wangke" 2>/dev/null
}

trap cleanup_temp EXIT

# 优化的按键监听函数
get_volume_key() {
# 清理旧的监听进程
pkill -f "getevent.*wangke" 2>/dev/null

# 设置超时（5秒无操作）
timeout=50
key_click=""

# 使用临时文件存储按键事件
rm -f "$TEMP_KEY_EVENT"

# 后台运行getevent，只监听一次
(getevent -qlc 1 2>/dev/null | awk '{print $3}' | grep -E 'KEY_VOLUME(UP|DOWN)' | head -n 1 > "$TEMP_KEY_EVENT" 2>/dev/null) &
getevent_pid=$!

# 等待按键或超时 - 使用兼容的while循环
i=0
while [ $i -lt $timeout ]; do
if [ -f "$TEMP_KEY_EVENT" ] && [ -s "$TEMP_KEY_EVENT" ]; then
key_click=$(cat "$TEMP_KEY_EVENT")
break
fi
sleep 0.5
i=$((i + 1))
done

# 清理进程
kill $getevent_pid 2>/dev/null
wait $getevent_pid 2>/dev/null
rm -f "$TEMP_KEY_EVENT" 2>/dev/null

echo "$key_click"
}

# 更新配置选项
update_config_selection() {
echo " "
echo "🔄 是否更新配置？"
echo "  音量上键 ➡️ 跳过更新"
echo "  音量下键 ➡️ 更新模块"
echo "⏱️ 等待按键中..."

key_click=$(get_volume_key)

case "$key_click" in
"KEY_VOLUMEUP")
echo "✅ 已选择：跳过更新"
;;
"KEY_VOLUMEDOWN")
echo "✅ 已选择：更新模块"
if [ -f "$UPDATE_SCRIPT" ]; then
echo "🔧 正在执行更新脚本..."
"$UPDATE_SCRIPT"
echo "✅ 更新配置完成"
else
echo "⚠️ 更新脚本不存在: $UPDATE_SCRIPT"
fi
;;
*)
echo "❌ 无操作，默认跳过更新"
;;
esac
}

# 创建配置目录
mkdir -p "/data/adb/亡客"

# 写入配置函数
set_config() {
key="$1"
value="$2"
if [ ! -f "$CONFIG_FILE" ]; then
touch "$CONFIG_FILE"
fi
grep -v "^${key}=" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" 2>/dev/null
echo "${key}=${value}" >> "${CONFIG_FILE}.tmp"
mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
}

# 读取配置函数
get_config() {
key="$1"
default="$2"
if [ -f "$CONFIG_FILE" ]; then
val=$(grep "^${key}=" "$CONFIG_FILE" | cut -d'=' -f2)
if [ -n "$val" ]; then
echo "$val"
return
fi
fi
echo "$default"
}

# 显示状态函数
show_status() {
[ "$1" = "1" ] && echo "开启" || echo "关闭"
}

# 显示范围状态
show_range_status() {
range_key="$1"
default_value="$2"
range_val=$(get_config "$range_key" "0:$default_value")
status="${range_val%%:*}"
value="${range_val#*:}"
if [ "$status" = "1" ]; then
echo "开启 [$value]"
else
echo "关闭 [$value]"
fi
}

# 简化的打印菜单头部
print_header() {
echo "----------------------------------"
echo "❇️ 亡客公益频道@wangkela"
echo "♻️ 10.0版本"
echo "🔰【当前配置状态】"

allGunNoRecoil=$(get_config "allGunNoRecoil" "0")
hasCrosshair=$(get_config "hasCrosshair" "0")
noCrosshair=$(get_config "noCrosshair" "0")
fullBodyRange=$(get_config "fullBodyRange" "0")
bodySize=$(get_config "bodySize" "0.5身位")

echo "全枪无后[$(show_status $allGunNoRecoil)]"
echo "有准心聚点[$(show_status $hasCrosshair)]"
echo "无准心聚点[$(show_status $noCrosshair)]"
echo "全身范围[$(show_status $fullBodyRange)]"
echo "身位选择[$bodySize]"
echo "头部范围[$(show_range_status 'headRange' '12.585')]"
echo "胸部范围[$(show_range_status 'chestRange' '21')]"
echo "腹部范围[$(show_range_status 'abdomenRange' '18')]"
echo "腿部范围[$(show_range_status 'legRange' '15')]"
echo "----------------------------------"
}

# 范围配置函数
config_range() {
range_name="$1"
range_key="$2"
default_value="$3"

clear
print_header
echo "🔧 正在配置: [$range_name]"
echo ""

current_range=$(get_config "$range_key" "0:$default_value")
status="${current_range%%:*}"
current_value="${current_range#*:}"
current_int="${current_value%.*}"

if [ -z "$current_int" ] || ! echo "$current_int" | grep -q '^[0-9]\+$'; then
current_int=0
fi

echo "当前状态: $(if [ "$status" = "1" ]; then echo "开启 数值: $current_int"; else echo "关闭"; fi)"
echo "👉 ▲音量+ = 开启/设置数值  ▼音量- = 关闭"

key_click=$(get_volume_key)

case "$key_click" in
*VOLUMEUP*)
selected_value=20
if [ "$status" = "1" ] && [ "$current_int" -gt 0 ] 2>/dev/null; then
selected_value="$current_int"
fi

clear
print_header
echo "🔧 设置[$range_name]数值 (0-200)"
echo "当前数值: $selected_value"
echo "👉 ▲音量+ = 确定  ▼音量- = 切换"

while true; do
key_click2=$(get_volume_key)

case "$key_click2" in
*VOLUMEUP*)
set_config "$range_key" "1:${selected_value}"
echo "✅ [$range_name]已开启: $selected_value"
sleep 0.5
break
;;
*VOLUMEDOWN*)
if [ "$selected_value" -lt 200 ] 2>/dev/null; then
selected_value=$((selected_value + 10))
else
selected_value=0
fi
clear
print_header
echo "🔧 设置[$range_name]数值 (0-200)"
echo "当前数值: $selected_value"
echo "👉 ▲音量+ = 确定  ▼音量- = 切换"
;;
esac
done
;;
*VOLUMEDOWN*)
set_config "$range_key" "0:${default_value}"
echo "✅ [$range_name]已关闭"
sleep 0.5
;;
esac
}


# 优化的身位选择函数
select_body_size() {
echo "❗️ ▲音量+ 是确定 ▼音量- 是切换"
echo "选择身位大小"

sizes="0.5身位 1.0身位 1.5身位 2.0身位 2.5身位"
current_index=1
size_count=5

while true; do
# 获取当前身位
case $current_index in
1) current_size="0.5身位" ;;
2) current_size="1.0身位" ;;
3) current_size="1.5身位" ;;
4) current_size="2.0身位" ;;
5) current_size="2.5身位" ;;
esac

echo "👉 $current_size"
key_click=$(get_volume_key)

case "$key_click" in
*VOLUMEUP*)
set_config "bodySize" "$current_size"
echo "✅ 已选择: $current_size"
break
;;
*VOLUMEDOWN*)
current_index=$((current_index + 1))
if [ $current_index -gt $size_count ]; then
current_index=1
fi
;;
esac
done
}

# 显示配置选项
show_config_option() {
name="$1"
key="$2"
current_value=$(get_config "$key" "0")

echo "----------------------------------"
clear
print_header
echo "$name"
echo "当前状态: $(show_status $current_value)"
echo "👉 ▲音量+ = 开启  ▼音量- = 关闭"
}

# 主配置函数
main() {
echo "🔊 检测到上次的非默认配置"
echo "----------------------------------"
echo "是否使用上次保存的配置？"
echo ""
echo "  音量上键 ➡️ 是（使用配置）"
echo "  音量下键 ➡️ 否（重新配置）"
echo "----------------------------------"
echo "⏱️ 等待按键中..."

key_click=$(get_volume_key)

case "$key_click" in
*VOLUMEUP*)
echo "✅ 已选择：使用上次配置"
print_header
return 0
;;
*VOLUMEDOWN*)
echo "✅ 已选择：重新配置"
> "$CONFIG_FILE"
;;
*)
echo "❌ 无操作，默认重新配置"
> "$CONFIG_FILE"
;;
esac

# 全枪无后配置
show_config_option "全枪无后" "allGunNoRecoil"
key_click=$(get_volume_key)
case "$key_click" in
*VOLUMEUP*)
set_config "allGunNoRecoil" "1"
echo "✅ 全枪无后已开启"
;;
*VOLUMEDOWN*)
set_config "allGunNoRecoil" "0"
echo "✅ 全枪无后已关闭"
;;
esac
sleep 0.5

# 有准心聚点配置
show_config_option "有准心聚点" "hasCrosshair"
key_click=$(get_volume_key)
case "$key_click" in
*VOLUMEUP*)
set_config "hasCrosshair" "1"
set_config "noCrosshair" "0"  # 有准心时自动关闭无准心
echo "✅ 有准心聚点已开启"
;;
*VOLUMEDOWN*)
set_config "hasCrosshair" "0"
echo "✅ 有准心聚点已关闭"
;;
esac
sleep 0.5

# 无准心聚点配置（只有有准心关闭时才显示）
hasCrosshair=$(get_config "hasCrosshair" "0")
if [ "$hasCrosshair" = "0" ]; then
show_config_option "无准心聚点" "noCrosshair"
key_click=$(get_volume_key)
case "$key_click" in
*VOLUMEUP*)
set_config "noCrosshair" "1"
echo "✅ 无准心聚点已开启"
;;
*VOLUMEDOWN*)
set_config "noCrosshair" "0"
echo "✅ 无准心聚点已关闭"
;;
esac
sleep 0.5
else
set_config "noCrosshair" "0"
fi

# 全身范围配置
show_config_option "全身范围" "fullBodyRange"
key_click=$(get_volume_key)
case "$key_click" in
*VOLUMEUP*)
set_config "fullBodyRange" "1"
echo "✅ 全身范围已开启"
select_body_size
;;
*VOLUMEDOWN*)
set_config "fullBodyRange" "0"
set_config "bodySize" "0.5身位"
echo "✅ 全身范围已关闭"
;;
esac

# 写入标识文件
echo "@wangkela" > "/data/adb/亡客/wangke.txt"

# 配置各个范围
echo "----------------------------------"
echo "配置范围参数"
echo ""

config_range "头部范围" "headRange" "12.585"
config_range "胸部范围" "chestRange" "21"
config_range "腹部范围" "abdomenRange" "18"
config_range "腿部范围" "legRange" "15"

# 检查并创建/删除文件
if [ -f "$CONFIG_FILE" ]; then
has_range=0
# 检查每个范围
for range_key in headRange chestRange abdomenRange legRange; do
range_val=$(grep "^${range_key}=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2)
if echo "$range_val" | grep -q "^1:" && [ "${range_val#*:}" != "0" ]; then
has_range=1
break
fi
done

if [ $has_range -eq 1 ]; then
echo "" > "/data/adb/亡客/wangke"
echo "✅ 检测到范围配置，已创建 /data/adb/亡客/wangke"
else
rm -f "/data/adb/亡客/wangke" 2>/dev/null
echo "✅ 所有范围均为0，已清理文件"
fi
else
echo "⚠️ 配置文件不存在"
fi

echo ""
clear
print_header
echo "✅ 所有功能配置完成"
}

# 启动控制模块
start_control_module() {
echo " "
echo "🔊 请使用音量键选择操作："
echo "  音量上键 ➡️ 启动模块"
echo "  音量下键 ➡️ 停止模块"
echo "⏱️ 等待按键中..."

key_click=$(get_volume_key)

case "$key_click" in
"KEY_VOLUMEUP")
echo "✅ 已选择：启动模块"
if pgrep -f "wangke.sh" > /dev/null; then
echo "✅ wangke.sh 正在运行"
else
echo "🚀 正在启动 wangke.sh..."
/system/bin/sh "/data/adb/modules/wangke/wangke.sh" &
sleep 1
if pgrep -f "wangke.sh" > /dev/null; then
echo "✅ 启动成功"
else
echo "❌ 启动失败"
fi
fi
;;
"KEY_VOLUMEDOWN")
echo "✅ 已选择：停止模块"
killall "wangke.sh" 2>/dev/null
pkill -f "wangke.sh" 2>/dev/null
echo "🛑 正在停止 wangke.sh 进程..."
sleep 1
if ! pgrep -f "wangke.sh" > /dev/null; then
echo "✅ 停止模块成功"
else
echo "⚠️ 停止失败，请手动检查"
fi
;;
*)
echo "❌ 无操作，默认停止模块"
killall "wangke.sh" 2>/dev/null
pkill -f "wangke.sh" 2>/dev/null
;;
esac
}

# 主执行流程
echo "📦 WangKe 模块控制脚本"
echo "------------------------"
update_config_selection
sleep 0.5
main
sleep 0.5
start_control_module
cleanup_temp
