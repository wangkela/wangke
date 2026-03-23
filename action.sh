#!/bin/sh
chmod 777 "/data/adb/modules/wangke/wangke.sh"
chmod 777 "/data/adb/modules/wangke/action.sh"
chmod 777 "/data/adb/modules/wangke/wangkela.sh"
MODDIR="/data/adb/modules/wangke"
UPDATE_SCRIPT="$MODDIR/gx.sh"
# 音量键选择功能 - 更新配置选项
update_config_selection() {
echo " "
echo "🔄 是否更新配置？"
echo "  音量上键 ➡️ 跳过更新"
echo "  音量下键 ➡️ 更新模块"
echo "⏱️ 等待按键中..."

key_click=""
while [ -z "$key_click" ]; do
# 实时监听音量键事件
key_click=$(getevent -qlc 1 2>/dev/null | awk '{print $3}' | grep -E 'KEY_VOLUME(UP|DOWN)' | head -n 1)
sleep 0.5
done

case "$key_click" in
"KEY_VOLUMEUP")
echo "✅ 已选择：跳过更新"
;;
"KEY_VOLUMEDOWN")
echo "✅ 已选择：更新模块"
# 检查更新脚本是否存在
if [ -f "$UPDATE_SCRIPT" ]; then
echo "🔧 正在执行更新脚本..."
"$UPDATE_SCRIPT"
echo "✅ 更新配置完成"
else
echo "⚠️ 更新脚本不存在: $UPDATE_SCRIPT"
fi
;;
*)
echo "❓ 未知按键，默认跳过更新"
;;
esac
}
# 打印菜单头部函数
print_header() {    
clear
echo "🔊 请使用音量键选择"
echo "----------------------------------"
echo "❇️ 亡客公益频道@wangkela"
echo "♻️ 9.0版本"
echo "🔰【当前配置状态】"

# 重新读取当前配置以确保状态准确
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

CONFIG_FILE="/data/adb/亡客/pz.ini"

# 创建配置目录
mkdir -p "/data/adb/亡客"

# 写入配置函数
set_config() {
key=$1
value=$2
# 先删除现有的键值
sed -i "/^${key}=/d" "$CONFIG_FILE" 2>/dev/null
# 添加新的键值
echo "${key}=${value}" >> "$CONFIG_FILE"
}

# 读取配置函数
get_config() {
key=$1
default=$2
if [ -f "$CONFIG_FILE" ]; then
val=$(grep "^${key}=" "$CONFIG_FILE" | cut -d'=' -f2)
if [ -n "$val" ]; then
echo "$val"
return
fi
fi
echo "$default"
}

# 显示当前状态函数
show_status() {
if [ "$1" = "1" ]; then
echo "开启"
else
echo "关闭"
fi
}

# 显示范围状态函数
show_range_status() {
range_key=$1
default_value=$2
range_val=$(get_config "$range_key" "0:$default_value")
status=${range_val%%:*}
value=${range_val#*:}
if [ "$status" = "1" ]; then
echo "开启 [$value]"
else
echo "关闭 [$value]"
fi
}

# 范围配置函数
config_range() {
range_name=$1
range_key=$2
default_value=$3
current_range=$(get_config "$range_key" "0:$default_value")
status=${current_range%%:*}
current_value=${current_range#*:}
current_int=${current_value%.*}

print_header
echo "$range_name"
echo "当前: $(if [ "$status" = "1" ]; then echo "开启 数值: $current_int"; else echo "关闭"; fi)"
echo "👉 ▲音量+ = 开启/设置数值  ▼音量- = 关闭"

# 等待按键选择
key_click=""
while [ -z "$key_click" ]; do
key_click=$(getevent -qlc 1 2>/dev/null | awk '{print $3}' | grep -E 'KEY_VOLUME(UP|DOWN)' | head -n 1)
sleep 0.5
done

case "$key_click" in
*VOLUMEUP*)
# 开启并设置数值 - 这里修改：默认从20开始
selected_value=20
if [ "$status" = "1" ] && [ "$current_int" -gt 0 ]; then
# 如果当前已经是开启状态，使用当前值
selected_value=$current_int
fi

print_header
echo "设置$range_name数值 (0-200)"
echo "当前: $selected_value"
echo "👉 ▲音量+ = 确定  ▼音量- = 切换"

value_loop=true
while $value_loop; do
echo "数值: $selected_value"
key_click=""
while [ -z "$key_click" ]; do
key_click=$(getevent -qlc 1 2>/dev/null | awk '{print $3}' | grep -E 'KEY_VOLUME(UP|DOWN)' | head -n 1)
sleep 0.1
done

case "$key_click" in
*VOLUMEUP*)
set_config "$range_key" "1:${selected_value}"
echo "✅ ${range_name}已开启: $selected_value"
value_loop=false
sleep 0.5
;;
*VOLUMEDOWN*)
# 切换到下一个值，每次+10
if [ $selected_value -lt 200 ]; then
selected_value=$((selected_value + 10))
else
selected_value=0
fi
print_header
echo "设置$range_name数值 (0-200)"
echo "当前: $selected_value"
echo "👉 ▲音量+ = 确定  ▼音量- = 切换"
;;
esac
done
;;
*VOLUMEDOWN*)
# 关闭
set_config "$range_key" "0:${default_value}"
echo "✅ ${range_name}已关闭"
sleep 0.5
;;
esac
}

main() {
# 读取当前配置
allGunNoRecoil=$(get_config "allGunNoRecoil" "0")
hasCrosshair=$(get_config "hasCrosshair" "0")
noCrosshair=$(get_config "noCrosshair" "0")
fullBodyRange=$(get_config "fullBodyRange" "0")
bodySize=$(get_config "bodySize" "0.5身位")

print_header
echo "🔊 检测到上次的非默认配置"
echo "----------------------------------"
echo "是否使用上次保存的配置？"
echo ""
echo "  音量上键 ➡️ 是（使用配置）"
echo "  音量下键 ➡️ 否（重新配置）"
echo "----------------------------------"
echo "⏱️ 等待按键中..."

key_click=""
while [ -z "$key_click" ]; do
key_click=$(getevent -qlc 1 2>/dev/null | awk '{print $3}' | grep -E 'KEY_VOLUME(UP|DOWN)' | head -n 1)
sleep 0.5
done

case "$key_click" in
*VOLUMEUP*)
echo "✅ 已选择：使用上次配置"
return 0
;;
*VOLUMEDOWN*)
echo "✅ 已选择：重新配置"
# 清空配置重新开始
> "$CONFIG_FILE"
;;
esac

# 全枪无后
echo "全枪无后"
echo "👉 ▲音量+ = 开启  ▼音量- = 关闭"
while true; do
key_click=""
while [ -z "$key_click" ]; do
key_click=$(getevent -qlc 1 2>/dev/null | awk '{print $3}' | grep -E 'KEY_VOLUME(UP|DOWN)' | head -n 1)
sleep 0.5
done
case "$key_click" in
*VOLUMEUP*)
set_config "allGunNoRecoil" "1"
allGunNoRecoil=1
print_header
break
;;
*VOLUMEDOWN*)
set_config "allGunNoRecoil" "0"
allGunNoRecoil=0
print_header
break
;;
esac
done

# 有准心聚点
echo "有准心聚点"
echo "👉 ▲音量+ = 开启  ▼音量- = 关闭"
while true; do
key_click=""
while [ -z "$key_click" ]; do
key_click=$(getevent -qlc 1 2>/dev/null | awk '{print $3}' | grep -E 'KEY_VOLUME(UP|DOWN)' | head -n 1)
sleep 0.5
done
case "$key_click" in
*VOLUMEUP*)
set_config "hasCrosshair" "1"
hasCrosshair=1
noCrosshair=0
break
;;
*VOLUMEDOWN*)
set_config "hasCrosshair" "0"
hasCrosshair=0
print_header
break
;;
esac
done

# 无准心聚点
if [ "$hasCrosshair" = "1" ]; then
set_config "noCrosshair" "0"
noCrosshair=0
print_header
else
echo "无准心聚点"
echo "👉 ▲音量+ = 开启  ▼音量- = 关闭"
while true; do
key_click=""
while [ -z "$key_click" ]; do
key_click=$(getevent -qlc 1 2>/dev/null | awk '{print $3}' | grep -E 'KEY_VOLUME(UP|DOWN)' | head -n 1)
sleep 0.5
done
case "$key_click" in
*VOLUMEUP*)
set_config "noCrosshair" "1"
noCrosshair=1
print_header
break
;;
*VOLUMEDOWN*)
set_config "noCrosshair" "0"
noCrosshair=0
print_header
break
;;
esac
done
fi

# 全身范围
echo "全身范围"
echo "👉 ▲音量+ = 开启  ▼音量- = 关闭"
while true; do
key_click=""
while [ -z "$key_click" ]; do
key_click=$(getevent -qlc 1 2>/dev/null | awk '{print $3}' | grep -E 'KEY_VOLUME(UP|DOWN)' | head -n 1)
sleep 0.5
done
case "$key_click" in
*VOLUMEUP*)
set_config "fullBodyRange" "1"
fullBodyRange=1
print_header
echo "❗️ ▲音量+ 是确定 ▼音量- 是切换"
echo "选择身位大小"
echo "👉 0.5身位"

body_choice_loop=true
while $body_choice_loop; do
key_click=""
while [ -z "$key_click" ]; do
key_click=$(getevent -qlc 1 2>/dev/null | awk '{print $3}' | grep -E 'KEY_VOLUME(UP|DOWN)' | head -n 1)
sleep 0.5
done
case "$key_click" in
*VOLUMEUP*)
echo "已选择: 0.5身位"
set_config "bodySize" "0.5身位"
bodySize="0.5身位"
print_header
body_choice_loop=false
;;
*VOLUMEDOWN*)
echo "👉 1.0身位"
while true; do
key_click=""
while [ -z "$key_click" ]; do
key_click=$(getevent -qlc 1 2>/dev/null | awk '{print $3}' | grep -E 'KEY_VOLUME(UP|DOWN)' | head -n 1)
sleep 0.5
done
case "$key_click" in
*VOLUMEUP*)
set_config "bodySize" "1.0身位"
bodySize="1.0身位"
print_header
body_choice_loop=false
break
;;
*VOLUMEDOWN*)
echo "👉 1.5身位"
while true; do
key_click=""
while [ -z "$key_click" ]; do
key_click=$(getevent -qlc 1 2>/dev/null | awk '{print $3}' | grep -E 'KEY_VOLUME(UP|DOWN)' | head -n 1)
sleep 0.5
done
case "$key_click" in
*VOLUMEUP*)
set_config "bodySize" "1.5身位"
bodySize="1.5身位"
print_header
body_choice_loop=false
break
;;
*VOLUMEDOWN*)
echo "👉 2.0身位"
while true; do
key_click=""
while [ -z "$key_click" ]; do
key_click=$(getevent -qlc 1 2>/dev/null | awk '{print $3}' | grep -E 'KEY_VOLUME(UP|DOWN)' | head -n 1)
sleep 0.5
done
case "$key_click" in
*VOLUMEUP*)
set_config "bodySize" "2.0身位"
bodySize="2.0身位"
print_header
body_choice_loop=false
break
;;
*VOLUMEDOWN*)
echo "👉 2.5身位"
while true; do
key_click=""
while [ -z "$key_click" ]; do
key_click=$(getevent -qlc 1 2>/dev/null | awk '{print $3}' | grep -E 'KEY_VOLUME(UP|DOWN)' | head -n 1)
sleep 0.5
done
case "$key_click" in
*VOLUMEUP*)
set_config "bodySize" "2.5身位"
bodySize="2.5身位"
print_header
body_choice_loop=false
break
;;
*VOLUMEDOWN*)
echo "👉 0.5身位"
break
;;
esac
done
;;
esac
done
;;
esac
done
;;
esac
done
;;
esac
done
break
;;
*VOLUMEDOWN*)
set_config "fullBodyRange" "0"
set_config "bodySize" "0.5身位"
fullBodyRange=0
bodySize="0.5身位"
break
;;
esac
done

echo "@wangkela" > "/data/adb/亡客/wangke.txt"

# 配置各个范围
config_range "头部范围" "headRange" "12.585"
config_range "胸部范围" "chestRange" "21"
config_range "腹部范围" "abdomenRange" "18"
config_range "腿部范围" "legRange" "15"

print_header
# 读取配置文件
if [[ -f "/data/adb/亡客/pz.ini" ]]; then
# 提取关键值（假设格式为 key=value）
head_range=$(grep -E "^headRange=" "/data/adb/亡客/pz.ini" | cut -d= -f2)
chest_range=$(grep -E "^chestRange=" "/data/adb/亡客/pz.ini" | cut -d= -f2)
abdomen_range=$(grep -E "^abdomenRange=" "/data/adb/亡客/pz.ini" | cut -d= -f2)
leg_range=$(grep -E "^legRange=" "/data/adb/亡客/pz.ini" | cut -d= -f2)

# 判断条件：任一范围的值不为"0"（这里假设值可能是"0"或"1"）
if [[ "$head_range" != "0" ]] || [[ "$chest_range" != "0" ]] || \
[[ "$abdomen_range" != "0" ]] || [[ "$leg_range" != "0" ]]; then
# 创建文件（覆盖写入空内容）
echo "" > "/data/adb/亡客/wangke"
echo "检测到非零值，已创建 /data/adb/亡客/wangke"
else
# 删除文件
rm -rf "/data/adb/亡客/wangke"
echo "所有范围均为0，已删除 /data/adb/亡客/wangke"
fi
else
echo "配置文件 /data/adb/亡客/pz.ini 不存在"
fi

echo "所有功能已配置完成"
}
update_config_selection
main

#!/system/bin/sh

# ========================================
# 模块名称: WangKe控制模块
# 功能: 倒计时停止模块 + 音量键选择操作
# 作者: 亡客
# ========================================

# 全局变量
MODDIR="/data/adb/modules/wangke"
SCRIPT_PATH="$MODDIR/wangke.sh"

# 显示信息函数
print_info() {
echo "📦 WangKe 模块控制脚本"
echo "------------------------"
}

# 倒计时 3 秒
countdown_stop() {
echo "⏳ 1秒后停止模块运行..."
for i in 1; do
echo "$i 秒后停止模块运行"
done
}

# 停止 wangke.sh 进程
stop_module() {
killall "wangke.sh" 2>/dev/null
echo "🛑 正在停止 wangke.sh 进程"
echo "✅ 停止模块成功"
}

# 检测并启动 wangke.sh
start_module() {
if pgrep -x "wangke.sh" > /dev/null; then
echo "✅ wangke.sh 正在运行"
echo "✅ 启动模块成功（已是运行状态）"
else
echo "🚀 wangke.sh 未运行，正在启动..."
"$SCRIPT_PATH" &
sleep 1
if pgrep -x "wangke.sh" > /dev/null; then
echo "✅ 启动成功"
echo "//亡客过检测模块关键配置文件" >> "/data/adb/亡客/pz.ini"
else
echo "❌ 启动失败，请检查日志"
fi
fi
}

# 音量键选择功能（仿 AnyKernel3）
volume_key_selection() {
echo " "
echo "🔊 请使用音量键选择操作："
echo "  音量上键 ➡️ 启动模块"
echo "  音量下键 ➡️ 停止模块"
echo "⏱️ 等待按键中..."

key_click=""
while [ -z "$key_click" ]; do
# 实时监听音量键事件
key_click=$(getevent -qlc 1 2>/dev/null | awk '{print $3}' | grep -E 'KEY_VOLUME(UP|DOWN)' | head -n 1)
sleep 0.1
done

case "$key_click" in
"KEY_VOLUMEUP")
echo "✅ 已选择：重启模块"
start_module
;;
"KEY_VOLUMEDOWN")
echo "✅ 已选择：停止模块"
stop_module
;;
*)
echo "❓ 未知按键，默认执行【停止模块】"
stop_module
;;
esac
}

# ==================== 主程序入口 ====================
# 执行音量键选择
volume_key_selection
print_info
countdown_stop
