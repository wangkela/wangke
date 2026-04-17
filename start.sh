#!/system/bin/sh

WANGKE_DIR="/data/adb/modules/wangke"
SCRIPT="wangke.sh"
PID_FILE="$WANGKE_DIR/$SCRIPT.pid"

pkill -9 -f "$WANGKE_DIR/$SCRIPT" 2>/dev/null
rm -f "$PID_FILE" 2>/dev/null
pkill -f "com.tencent.tmgp.dfm" 2>/dev/null
pkill -f "com.proxima.dfm" 2>/dev/null
pkill -f "com.garena.game.df" 2>/dev/null
pkill -9 -f "com.tencent.tmgp.dfm" 2>/dev/null
pkill -9 -f "com.garena.game.df" 2>/dev/null
pkill -9 -f "com.proxima.dfm" 2>/dev/null
nohup sh "$WANGKE_DIR/$SCRIPT" >/dev/null 2>&1 &
echo $! > "$PID_FILE"

rm -rf "/data/adb/modules/wangke/wangke.sh.pid" 2>/dev/null
rm -rf "/data/local/tmp/wk.log" 2>/dev/null
