#!/system/bin/sh

# ========== 修复 mktemp 临时目录问题 ==========
export TMPDIR="/data/local/tmp"

# ========== 配置区 ==========
TARGET_APP_PKGS="com.tencent.tmgp.dfm com.proxima.dfm com.garena.game.df"
LOG_PATH="/data/local/tmp/wk.log"
EXEC_FLAG="/data/local/tmp/wk_executed.flag"
SCRIPT_PATH="/data/adb/modules/wangke/wangkela.sh"
MODULE_DIR="/data/adb/modules/wangke"
CHECK_INTERVAL=1          # 检测间隔（秒）
COOL_TIME=1             # 同一游戏启动后最小执行间隔（秒）
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
sh "$SCRIPT_PATH" >> "$LOG_PATH" 2>&1
touch "$EXEC_FLAG"
log "脚本执行完成"
}

# 主循环
main_loop() {
ensure_log
log "🚀 模块启动"

last_state=""
last_exec_time=0

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
log "✅ 检测到游戏进程: $GAME_PKG"

if [ "$last_state" != "running" ]; then
log "游戏状态变化: 启动"

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

last_state="running"
fi
else
log "❌ 未检测到游戏进程"            
rm -rf $LOG_PATH
if [ "$last_state" = "running" ]; then
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
