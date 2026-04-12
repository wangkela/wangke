#!/system/bin/sh

# ========== 修复 mktemp 临时目录问题 ==========
export TMPDIR="/data/local/tmp"

# ========== 配置区 ==========
TARGET_APP_PKGS="com.tencent.tmgp.dfm com.proxima.dfm com.garena.game.df"
LOG_PATH="/data/local/tmp/wk.log"
EXEC_FLAG="/data/local/tmp/wk_executed.flag"
SCRIPT_PATH="/data/adb/modules/wangke/wangkela.sh"
MODULE_DIR="/data/adb/modules/wangke"
SPECIAL_TRIGGER_FILE="/data/adb/亡客/wangke"  # 新增：特殊触发文件路径
CHECK_INTERVAL=1          # 检测间隔（秒）
COOL_TIME=1               # 同一游戏启动后最小执行间隔（秒）
LOOP_EXEC_INTERVAL=60    # 循环执行模式下的执行间隔（秒）
# =============================

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

# 检测游戏是否运行，返回包名或空
get_running_game() {
for PKG in $TARGET_APP_PKGS; do
if su -c "ps -A | grep -w '$PKG' | grep -qv grep" >/dev/null 2>&1; then
echo "$PKG"
return
fi
done
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
# 确保可读可执行
chmod 777 "$SCRIPT_PATH" 2>/dev/null
log "执行 $SCRIPT_PATH"
"$SCRIPT_PATH" >> "$LOG_PATH" 2>&1
touch "$EXEC_FLAG"
log "脚本执行完成"
}

# 循环执行模式
loop_execution_mode() {
local GAME_PKG="$1"
log "🔁 进入循环执行模式 (检测到特殊触发文件)"

local LOOP_SLEEP_INTERVAL=1  # 每1秒检测一次游戏状态
local SCRIPT_INTERVAL=60     # 每60秒执行一次脚本

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
if [ $((now - last_run)) -ge $SCRIPT_INTERVAL ]; then
run_target_script
last_run=$now
fi

# 小睡，提高响应速度
sleep $LOOP_SLEEP_INTERVAL
done
}


# 单次执行模式
single_execution_mode() {
local GAME_PKG="$1"
log "⚡ 进入单次执行模式"

now=$(date +%s)
flag_time=0
[ -f "$EXEC_FLAG" ] && flag_time=$(date -r "$EXEC_FLAG" +%s 2>/dev/null || echo 0)

# 冷却时间内不重复执行
if [ $((now - flag_time)) -ge $COOL_TIME ]; then
log "准备执行脚本"
run_target_script
else
log "冷却时间内，跳过执行"
fi
}

# 主循环
main_loop() {
ensure_log
log "🚀 模块启动"

last_state=""
in_loop_mode=false

while true; do
ensure_log

# 模块被移除则退出
if ! check_module_exists; then
log "模块目录不存在，退出循环"
cleanup_flag
break
fi

GAME_PKG=$(get_running_game)

if [ -n "$GAME_PKG" ]; then

if [ "$last_state" != "running" ]; then
log "✅ 检测到游戏进程: $GAME_PKG"
log "游戏状态变化: 启动"

# 检查是否有特殊触发文件
if check_special_trigger; then
# 进入循环执行模式
in_loop_mode=true
loop_execution_mode "$GAME_PKG" &
loop_pid=$!
# 等待循环执行模式结束
wait $loop_pid 2>/dev/null
in_loop_mode=false
else
# 单次执行模式
single_execution_mode "$GAME_PKG"
fi

last_state="running"
fi
else
if [ "$last_state" = "running" ]; then
pkill -f "com.tencent.tmgp.dfm" 2>/dev/null
pkill -f "com.proxima.dfm" 2>/dev/null
pkill -f "com.garena.game.df" 2>/dev/null
pkill -9 -f "com.tencent.tmgp.dfm" 2>/dev/null
pkill -9 -f "com.garena.game.df" 2>/dev/null
pkill -9 -f "com.proxima.dfm" 2>/dev/null
rm -rf $LOG_PATH
log "游戏状态变化: 退出"
cleanup_flag
fi
last_state="stopped"
fi

sleep $CHECK_INTERVAL
done
}

# 捕获 SIGTERM 用于安全退出
trap 'log "收到终止信号，退出"; cleanup_flag; exit 0' INT TERM

# 启动主循环
main_loop
