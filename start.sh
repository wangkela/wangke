#!/system/bin/sh

WANGKE_DIR="/data/adb/modules/wangke"
SCRIPT="wangke.sh"
PID_FILE="$WANGKE_DIR/$SCRIPT.pid"

# 后台启动 wangke.sh
killall com.garena.game.df 2>/dev/null
killall com.proxima.dfm 2>/dev/null
killall com.tencent.tmgp.dfm 2>/dev/null
killall wangke.sh 2>/dev/null
nohup sh "$WANGKE_DIR/$SCRIPT" >/dev/null 2>&1 &
echo $! > "$PID_FILE"
rm -rf "/data/adb/modules/wangke/wangke.sh.pid"