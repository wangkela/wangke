#!/bin/sh

# 设置权限
chmod 777 "/data/adb/modules/wangke/wangke.sh"
chmod 777 "/data/adb/modules/wangke/action.sh"
chmod 777 "/data/adb/modules/wangke/wangkela.sh"

MODDIR="/data/adb/modules/wangke"
UPDATE_SCRIPT="$MODDIR/gx.sh"

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
gx=1
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
echo "@wangkela" > "/data/adb/亡客/wangke.txt"
echo "🚀 正在启动 wangke.sh..."
"/data/adb/modules/wangke/wangke.sh" &
sleep 0.5
if pgrep -f "wangke.sh" > /dev/null; then
echo "✅ 启动成功"
else
echo "❌ 启动失败"
fi
fi
;;
*)
echo "✅ 已选择：停止模块"
killall "wangke.sh" 2>/dev/null && echo "✅ 停止模块成功"
;;
esac
sleep 0.5
}

# 主执行流程
echo "📦 WangKe 模块控制脚本"
echo "------------------------"
gx=0
update_config_selection
if [ "$gx" -ne 1 ]; then
start_control_module
else
echo "退出"
fi
