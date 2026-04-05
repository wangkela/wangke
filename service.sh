#!/system/bin/sh
FOLDER="/data/adb/亡客"
if [ ! -d "$FOLDER" ]; then
mkdir -p "$FOLDER"
echo "文件夹已创建: $FOLDER"
else
echo "文件夹已存在，跳过创建: $FOLDER"
fi
chmod 777 "/data/adb/modules/wangke/wangke.sh"
chmod 777 "/data/adb/modules/wangke/gx.sh"
chmod 777 "/data/adb/modules/wangke/wangkela.sh"
chmod 777 "/data/adb/modules/wangke/stop.sh"
chmod 777 "/data/adb/modules/wangke/start.sh"