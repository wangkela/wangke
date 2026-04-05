#!/system/bin/sh

WANGKE_DIR="/data/adb/modules/wangke"
SCRIPT="gx.sh"
PID_FILE="$WANGKE_DIR/gx.pid.txt"

# 后台启动 wangke.sh
killall gx.sh 2>/dev/null
nohup sh "$WANGKE_DIR/$SCRIPT" >/dev/null 2>&1 &
echo $! > "$PID_FILE"