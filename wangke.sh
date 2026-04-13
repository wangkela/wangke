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
LOOP_SLEEP_INTERVAL=0.5     # 循环模式内的休眠间隔（秒），调大以提高稳定性
# =============================

# 全局变量：跟踪循环模式的子进程PID，防止残留
LOOP_PID=""

# 日志函数
log() {
echo "$(date '+%Y-%m-%d %H:%M:%S') : $1" >> "$LOG_PATH"
}

# 确保日志文件存在
ensure_log() {
if [ ! -f "$LOG_PATH" ]; then
touch "$LOG_PATH" 2>/dev/null || log "无法创建日志文件"
fi
}

# 检测模块是否还在
check_module_exists() {
[ -d "$MODULE_DIR" ]
}

# 检测特殊触发文件是否存在
check_special_trigger() {
[ -f "$SPECIAL_TRIGGER_FILE" ]
}

# 检测游戏是否运行，返回包名或空（优化版：使用pidof，减少su调用次数）
get_running_game() {
local out=$(su -c "ps -A -o CMDLINE | grep -E '^com\\.tencent\\.tmgp\\.dfm|^com\\.proxima\\.dfm|^com\\.garena\\.game\\.df'")
for PKG in $TARGET_APP_PKGS; do
if echo "$out" | grep -q "^$PKG"; then
echo "$PKG"
return
fi
done
echo ""
}


# 清理标记
cleanup_flag() {
rm -f "$EXEC_FLAG" 2>/dev/null
}

# 执行目标脚本
run_target_script() {
if [ ! -f "$SCRIPT_PATH" ]; then
log "目标脚本不存在: $SCRIPT_PATH"
return
fi
chmod 777 "$SCRIPT_PATH" 2>/dev/null
log "执行 $SCRIPT_PATH"
sleep 1s
"$SCRIPT_PATH" >> "$LOG_PATH" 2>&1
touch "$EXEC_FLAG"
log "脚本执行完成"
}

# 循环执行模式（独立子进程）
loop_execution_mode() {
local GAME_PKG="$1"
log "🔁 进入循环执行模式 (检测到特殊触发文件)"

# 设置陷阱：当父进程退出或脚本被终止时，此子进程也自动退出
trap 'log "循环模式子进程收到终止信号，退出"; exit 0' EXIT INT TERM

local last_run=0
while true; do
ensure_log

# 检查模块是否还在
if ! check_module_exists; then
log "模块目录不存在，退出循环执行模式"
cleanup_flag
break
fi

# 检查游戏是否仍在运行
if [ -z "$(get_running_game)" ]; then
log "游戏已停止，退出循环执行模式"
cleanup_flag
break
fi

# 检查特殊触发文件是否仍然存在
if ! check_special_trigger; then
log "特殊触发文件已移除，退出循环执行模式"
cleanup_flag
break
fi

# 按 SCRIPT_INTERVAL 执行目标脚本
now=$(date +%s)
if [ $((now - last_run)) -ge $LOOP_EXEC_INTERVAL ]; then
run_target_script
last_run=$now
fi

# 休眠，减少CPU占用并提高系统调度稳定性
sleep $LOOP_SLEEP_INTERVAL
done
}

# 单次执行模式
single_execution_mode() {
local GAME_PKG="$1"
log "⚡ 进入单次执行模式"
log "准备执行脚本"
run_target_script
}

# 主循环
main_loop() {
ensure_log
log "🚀 模块启动"

last_state=""
# LOOP_PID="" 已在全局初始化

while true; do
ensure_log

# 模块被移除则退出主循环
if ! check_module_exists; then
log "模块目录不存在，退出主循环"
cleanup_flag
# 确保终止所有残留的循环子进程
if [ -n "$LOOP_PID" ] && ps -p "$LOOP_PID" >/dev/null 2>&1; then
kill "$LOOP_PID" 2>/dev/null
wait "$LOOP_PID" 2>/dev/null
fi
break
fi

CURRENT_GAME=$(get_running_game)

if [ -n "$CURRENT_GAME" ]; then
# 游戏状态：运行中
if [ "$last_state" != "running" ]; then
log "✅ 检测到游戏进程: $CURRENT_GAME"
log "游戏状态变化: 启动"

# 检查是否有特殊触发文件
if check_special_trigger; then
# --- 进入循环执行模式 ---
# 关键：先清理旧的子进程，防止多个循环模式叠加
if [ -n "$LOOP_PID" ] && ps -p "$LOOP_PID" >/dev/null 2>&1; then
log "检测到旧循环进程 ($LOOP_PID)，正在终止..."
kill "$LOOP_PID" 2>/dev/null
wait "$LOOP_PID" 2>/dev/null
fi
# 启动新的循环子进程
loop_execution_mode "$CURRENT_GAME" &
LOOP_PID=$!  # 记录新子进程PID
log "循环执行模式已启动，子进程PID: $LOOP_PID"
else
# --- 进入单次执行模式 ---
single_execution_mode "$CURRENT_GAME"
fi
last_state="running"
fi
else
# 游戏状态：未运行
if [ "$last_state" = "running" ]; then
log "游戏状态变化: 退出"
cleanup_flag
# 游戏退出时，终止循环子进程
if [ -n "$LOOP_PID" ] && ps -p "$LOOP_PID" >/dev/null 2>&1; then
log "游戏已退出，终止循环子进程 ($LOOP_PID)..."
kill "$LOOP_PID" 2>/dev/null
wait "$LOOP_PID" 2>/dev/null
LOOP_PID=""  # 清空PID
fi
fi
last_state="stopped"
fi

sleep $CHECK_INTERVAL
done
}

# 捕获 SIGTERM 用于安全退出
trap 'log "收到终止信号，退出"; cleanup_flag; exit 0' INT TERM
pkill -f "com.tencent.tmgp.dfm" 2>/dev/null
pkill -f "com.proxima.dfm" 2>/dev/null
pkill -f "com.garena.game.df" 2>/dev/null
pkill -9 -f "com.tencent.tmgp.dfm" 2>/dev/null
pkill -9 -f "com.garena.game.df" 2>/dev/null
pkill -9 -f "com.proxima.dfm" 2>/dev/null
# 启动主循环
main_loop
