#!/system/bin/sh

# ========== 修复 mktemp 临时目录问题 ==========
export TMPDIR="/data/local/tmp"

# ========== 配置区 ==========
TARGET_APP_PKGS="com.tencent.tmgp.dfm com.proxima.dfm com.garena.game.df"
LOG_PATH="/data/local/tmp/wk.log"
EXEC_FLAG="/data/local/tmp/wk_executed.flag"
SCRIPT_PATH="/data/adb/modules/wangke/wangkela.sh"
MODULE_DIR="/data/adb/modules/wangke"
SPECIAL_TRIGGER_FILE="/data/adb/亡客/wangke"
CHECK_INTERVAL=0.5          # 主循环检测间隔（秒）
LOOP_EXEC_INTERVAL=60       # 循环执行模式下的脚本执行间隔（秒）
LOOP_SLEEP_INTERVAL=0.5     # 循环模式内休眠间隔（秒）
# =============================

# 日志函数
log() {
echo "$(date '+%Y-%m-%d %H:%M:%S') : $1" >> "$LOG_PATH"
}

# 确保日志文件存在
ensure_log() {
[ -f "$LOG_PATH" ] || touch "$LOG_PATH" 2>/dev/null
}

# 检测模块是否存在
check_module_exists() {
[ -d "$MODULE_DIR" ]
}

# 检测特殊触发文件
check_special_trigger() {
[ -f "$SPECIAL_TRIGGER_FILE" ]
}

# 检测游戏是否在运行（核心判断）
get_running_game() {
for PKG in $TARGET_APP_PKGS; do
if su -c "pgrep -f \"^$PKG\$\"" >/dev/null 2>&1; then
echo "$PKG"
return
fi
done
echo ""
}

# 清理执行标记
cleanup_flag() {
rm -f "$EXEC_FLAG" 2>/dev/null
}

# 执行目标脚本
run_target_script() {
[ -f "$SCRIPT_PATH" ] || {
log "目标脚本不存在: $SCRIPT_PATH"
return
}

chmod 777 "$SCRIPT_PATH" 2>/dev/null
log "执行 $SCRIPT_PATH"
sleep 1
"$SCRIPT_PATH" >> "$LOG_PATH" 2>&1
touch "$EXEC_FLAG"
log "脚本执行完成"
}

# 循环执行模式（完全靠游戏进程判断）
loop_execution_mode() {
log "🔁 进入循环执行模式 (检测到特殊触发文件)"

trap 'log "循环模式子进程退出"; exit 0' EXIT INT TERM

local last_run=0

while true; do
ensure_log

# ✅ 游戏不在了 → 自动退出
if [ -z "$(get_running_game)" ]; then
log "游戏已停止，退出循环执行模式"
cleanup_flag
break
fi

# 模块被删
if ! check_module_exists; then
log "模块目录不存在，退出循环执行模式"
cleanup_flag
break
fi

# 特殊触发文件被移除
if ! check_special_trigger; then
log "特殊触发文件已移除，退出循环执行模式"
cleanup_flag
break
fi

# 定时执行
now=$(date +%s)
if [ $((now - last_run)) -ge $LOOP_EXEC_INTERVAL ]; then
run_target_script
last_run=$now
fi

sleep $LOOP_SLEEP_INTERVAL
done
}

# 单次执行模式
single_execution_mode() {
log "⚡ 进入单次执行模式"
run_target_script
}

# 主循环
main_loop() {
ensure_log
log "🚀 模块启动"

last_state=""

while true; do
ensure_log

# 模块被卸载
if ! check_module_exists; then
log "模块目录不存在，退出主循环"
cleanup_flag
break
fi

CURRENT_GAME=$(get_running_game)

if [ -n "$CURRENT_GAME" ]; then
if [ "$last_state" != "running" ]; then
log "✅ 检测到游戏进程: $CURRENT_GAME"

if check_special_trigger; then
loop_execution_mode "$CURRENT_GAME" &
else
single_execution_mode "$CURRENT_GAME"
fi
fi
last_state="running"
else
if [ "$last_state" = "running" ]; then
rm -rf "$LOG_PATH"
log "游戏状态变化: 退出"
cleanup_flag
fi
last_state="stopped"
fi

sleep $CHECK_INTERVAL
done
}

# 安全退出
trap 'log "收到终止信号，退出"; cleanup_flag; exit 0' INT TERM

# 启动
main_loop
