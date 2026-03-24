#!/bin/sh

# 设置权限
chmod 777 "/data/adb/modules/wangke/wangke.sh"
chmod 777 "/data/adb/modules/wangke/action.sh"
chmod 777 "/data/adb/modules/wangke/wangkela.sh"

MODDIR="/data/adb/modules/wangke"
UPDATE_SCRIPT="$MODDIR/gx.sh"
CONFIG_FILE="/data/adb/亡客/pz.ini"

countdown_stop() {
echo "⏳ 1秒后停止模块运行..."
for i in 1; do
echo "$i 秒后停止模块运行"
sleep 1
done
}

# 简化的按键监听函数
get_volume_key() {
# 设置超时（6秒无操作）
timeout=6
key_click=""

# 监听按键事件
i=1
while [ $i -le $timeout ]; do
key_click=$(getevent -qlc 1 2>/dev/null | awk '{print $3}' | grep -E 'KEY_VOLUME(UP|DOWN)' | head -n 1)
if [ -n "$key_click" ]; then
echo "$key_click"
return
fi
sleep 0.5
i=$((i + 1))
done

echo ""
}

# 快速按键函数
quick_key() {
# 快速监听按键（1秒内）
result=""
for i in 1 2; do
result=$(getevent -qlc 1 2>/dev/null | awk '{print $3}' | grep -E 'KEY_VOLUME(UP|DOWN)' | head -n 1)
if [ -n "$result" ]; then
echo "$result"
return
fi
sleep 0.5
done

echo ""
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
echo "✅ 更新模块成功"
countdown_stop
else
echo "⚠️ 更新脚本不存在: $UPDATE_SCRIPT"
fi
;;
*)
echo "❌ 无操作，默认跳过更新"
;;
esac
sleep 0.5
}

# 简化的创建配置目录
mkdir -p "/data/adb/亡客"

# 配置读写函数
set_config() {
key="$1"
value="$2"
[ -f "$CONFIG_FILE" ] || touch "$CONFIG_FILE"
grep -v "^${key}=" "$CONFIG_FILE" 2>/dev/null > "${CONFIG_FILE}.tmp"
echo "${key}=${value}" >> "${CONFIG_FILE}.tmp"
mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
}

get_config() {
key="$1"
default="$2"
[ -f "$CONFIG_FILE" ] && {
val=$(grep "^${key}=" "$CONFIG_FILE" | cut -d'=' -f2)
[ -n "$val" ] && { echo "$val"; return; }
}
echo "$default"
}

show_status() { 
if [ "$1" = "1" ]; then
echo "开启"
else
echo "关闭"
fi
}

show_range_status() {
range_val=$(get_config "$1" "0:$2")
status="${range_val%%:*}"
value="${range_val#*:}"
if [ "$status" = "1" ]; then
echo "开启 [$value]"
else
echo "关闭 [$value]"
fi
}

# 打印头部
clear
print_header() {
echo "----------------------------------"
echo "❇️ 亡客公益频道@wangkela"
echo "♻️ 10.0版本"
echo "🔰【当前配置状态】"

all_gun_status=$(show_status $(get_config "allGunNoRecoil" "0"))
has_cross_status=$(show_status $(get_config "hasCrosshair" "0"))
no_cross_status=$(show_status $(get_config "noCrosshair" "0"))
full_body_status=$(show_status $(get_config "fullBodyRange" "0"))
body_size_val=$(get_config "bodySize" "0.5身位")

echo "全枪无后[$all_gun_status]"
echo "有准心聚点[$has_cross_status]"
echo "无准心聚点[$no_cross_status]"
echo "全身范围[$full_body_status]"
echo "身位选择[$body_size_val]"
echo "头部范围[$(show_range_status 'headRange' '12.585')]"
echo "胸部范围[$(show_range_status 'chestRange' '21')]"
echo "腹部范围[$(show_range_status 'abdomenRange' '18')]"
echo "腿部范围[$(show_range_status 'legRange' '15')]"
echo "----------------------------------"
}

# 范围配置
config_range() {
local range_name="$1" 
local range_key="$2" 
local default_value="$3"

echo "🔧 正在配置: [$range_name]"
echo ""

current_range=$(get_config "$range_key" "0:$default_value")
status="${current_range%%:*}"
current_value="${current_range#*:}"
current_int="${current_value%.*}"

[ -z "$current_int" ] || echo "$current_int" | grep -q '^[0-9]\+$' || current_int=0

if [ "$status" = "1" ]; then
echo "当前状态: 开启 数值: $current_int"
else
echo "当前状态: 关闭"
fi

echo "👉 ▲音量+ = 开启/设置数值  ▼音量- = 关闭"

key_click=$(get_volume_key)

case "$key_click" in
"KEY_VOLUMEUP")
# 添加确认等待时间
sleep 0.5

selected_value=20
if [ "$status" = "1" ] && [ "$current_int" -gt 0 ] 2>/dev/null; then
selected_value="$current_int"
fi

echo "🔧 设置[$range_name]数值 (0-200)"
echo "当前数值: $selected_value"
echo "👉 ▲音量+ = 确定  ▼音量- = 切换"

while true; do
key_click2=$(get_volume_key)

case "$key_click2" in
"KEY_VOLUMEUP")
set_config "$range_key" "1:${selected_value}"
echo "✅ [$range_name]已开启: $selected_value"
# 添加确认后的等待时间
sleep 0.5
break
;;
"KEY_VOLUMEDOWN")
if [ "$selected_value" -lt 200 ] 2>/dev/null; then
selected_value=$((selected_value + 10))
else
selected_value=0
fi
echo "🔧 设置[$range_name]数值 (0-200)"
echo "当前数值: $selected_value"
echo "👉 ▲音量+ = 确定  ▼音量- = 切换"
sleep 0.5
;;
esac
done
sleep 0.5
;;
"KEY_VOLUMEDOWN")
# 添加关闭前的等待时间
sleep 0.5
set_config "$range_key" "0:${default_value}"
echo "✅ [$range_name]已关闭"
sleep 0.5
;;
esac
clear
print_header
}

# 身位选择
select_body_size() {
echo "❗️ ▲音量+ 是确定 ▼音量- 是切换"
echo "选择身位大小"

sizes="0.5身位 1.0身位 1.5身位 2.0身位 2.5身位"
current_index=0

# 将空格分隔的字符串转换为数组
set -- $sizes
size_count=$#

while true; do
index=0
for size in $sizes; do
if [ $index -eq $current_index ]; then
echo "👉 $size"
break
fi
index=$((index + 1))
done

key_click=$(get_volume_key)

case "$key_click" in
"KEY_VOLUMEUP")
# 获取当前选中的size
index=0
selected_size=""
for size in $sizes; do
if [ $index -eq $current_index ]; then
selected_size="$size"
break
fi
index=$((index + 1))
done

if [ -n "$selected_size" ]; then
set_config "bodySize" "$selected_size"
echo "✅ 已选择: $selected_size"
fi
break
;;
"KEY_VOLUMEDOWN")
current_index=$(( (current_index + 1) % $size_count ))
sleep 0.5
;;
esac
done
sleep 0.5
}

# 显示配置选项
show_config_option() {
clear
print_header
echo "$1"
status_val=$(get_config "$2" "0")
status_text=$(show_status "$status_val")
echo "当前状态: $status_text"
echo "👉 ▲音量+ = 开启  ▼音量- = 关闭"
}

# 主函数
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
"KEY_VOLUMEUP")
echo "✅ 已选择：使用上次配置"
return 0
;;
*)
echo "✅ 已选择：重新配置"
> "$CONFIG_FILE"
sleep 0.5
;;
esac
sleep 0.5

# 修复1: 全枪无后配置（移除错误的条件判断）
show_config_option "全枪无后" "allGunNoRecoil"
key_click=$(get_volume_key)
case "$key_click" in
"KEY_VOLUMEUP") 
set_config "allGunNoRecoil" "1"
echo "✅ 全枪无后已开启"
;;
"KEY_VOLUMEDOWN")
set_config "allGunNoRecoil" "0"
echo "✅ 全枪无后已关闭"
;;
esac
sleep 0.5

# 修复2: 有准心聚点配置（移除错误的条件判断）
show_config_option "有准心聚点" "hasCrosshair"
key_click=$(get_volume_key)
case "$key_click" in
"KEY_VOLUMEUP") 
set_config "hasCrosshair" "1"
echo "✅ 有准心聚点已开启"
;;
"KEY_VOLUMEDOWN")
set_config "hasCrosshair" "0"
echo "✅ 有准心聚点已关闭"
;;
esac
sleep 0.5

# 修复3: 无准心聚点配置（正确的互斥逻辑）
has_crosshair_val=$(get_config "hasCrosshair" "0")
if [ "$has_crosshair_val" = "0" ]; then
show_config_option "无准心聚点" "noCrosshair"
key_click=$(get_volume_key)
case "$key_click" in
"KEY_VOLUMEUP") 
set_config "noCrosshair" "1"
echo "✅ 无准心聚点已开启"
;;
"KEY_VOLUMEDOWN")
set_config "noCrosshair" "0"
echo "✅ 无准心聚点已关闭"
;;
esac
sleep 0.5
else
set_config "noCrosshair" "0"
#echo "⚠️ 有准心聚点已开启，自动关闭无准心聚点"
fi

# 全身范围配置
show_config_option "全身范围" "fullBodyRange"
key_click=$(get_volume_key)
case "$key_click" in
"KEY_VOLUMEUP")
set_config "fullBodyRange" "1"
echo "✅ 全身范围已开启"
select_body_size
;;
"KEY_VOLUMEDOWN")
set_config "fullBodyRange" "0"
set_config "bodySize" "0.5身位"
echo "✅ 全身范围已关闭"
;;
esac
sleep 0.5

# 写入标识文件
echo "@wangkela" > "/data/adb/亡客/wangke.txt"

# 配置各个范围
echo "----------------------------------"
echo "配置范围参数"
echo ""

ranges="头部范围:headRange:12.585
胸部范围:chestRange:21
腹部范围:abdomenRange:18
腿部范围:legRange:15"

echo "$ranges" | while IFS=':' read -r name key default; do
[ -z "$name" ] && continue
config_range "$name" "$key" "$default"
done

# 检查范围配置
if [ -f "$CONFIG_FILE" ]; then
has_range=0
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
"/data/adb/modules/wangke/wangke.sh" &
sleep 0.3
if pgrep -f "wangke.sh" > /dev/null; then
echo "✅ 启动成功"
countdown_stop
else
echo "❌ 启动失败"
fi
fi
;;
*)
echo "✅ 已选择：停止模块"
killall "wangke.sh" 2>/dev/null && echo "✅ 停止模块成功"
countdown_stop
;;
esac
sleep 0.5
}

# 主执行流程
echo "📦 WangKe 模块控制脚本"
echo "------------------------"
update_config_selection
main
sleep 0.5
start_control_module
