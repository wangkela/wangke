#!/system/bin/sh
# 定义变量
DOWNLOAD_URL="https://github.com/wangkela/wangke/archive/refs/heads/main.zip"
ZIP_FILE="main.zip"
EXTRACT_DIR="wangke-main"
INNER_ZIP_FILE="wangke.zip"
INNER_ZIP_PATH="$EXTRACT_DIR/$INNER_ZIP_FILE"
INNER_EXTRACT_DIR="wangke"
MODULE_DIR="/data/adb/modules/wangke"
TEMP_DIR="/data/adb/modules/wangke/$EXTRACT_DIR"
TOTAL_SIZE=254723  # 总文件大小

# 清理旧的模块文件和文件夹
rm -rf $MODULE_DIR/$ZIP_FILE
rm -rf $TEMP_DIR
rm -rf $MODULE_DIR/$INNER_ZIP_FILE

# 确保模块目录存在
mkdir -p $MODULE_DIR

# 进度变量
last_percentage=-1

main() {
# 1. 下载压缩包
echo "步骤 1/8: 开始下载文件..."

# 使用简单的进度显示
(
curl -L -o "$ZIP_FILE" "$DOWNLOAD_URL" --progress-bar
) &
CURL_PID=$!

# 简单的进度监控
while kill -0 $CURL_PID 2>/dev/null; do
if [ -f "$ZIP_FILE" ]; then
current_size=$(stat -c%s "$ZIP_FILE" 2>/dev/null || echo 0)
percentage=$((current_size * 100 / TOTAL_SIZE))

# 只有当百分比增加时才显示
if [ $percentage -gt $last_percentage ]; then
echo -ne "下载进度: $percentage%\r"
last_percentage=$percentage
fi
fi
sleep 1
done

wait $CURL_PID
CURL_EXIT=$?

# 显示最终进度
echo "下载进度: 100%"
echo ""  # 换行

if [ $CURL_EXIT -ne 0 ]; then
echo "❌ 下载失败，请检查网络和链接。"
exit 1
fi

echo "✅ 下载完成: $ZIP_FILE"

# 2. 将压缩包移动到模块目录并解压
echo "步骤 2/8: 移动并解压外层文件..."

# 检查是否安装了 unzip
if ! command -v unzip &> /dev/null; then
echo "❌ 需要安装 'unzip' 工具。"
echo "   请尝试执行: sudo apt-get install unzip 或 brew install unzip"
exit 1
fi

# 移动外层zip到模块目录
mv "$ZIP_FILE" "$MODULE_DIR/"
if [ $? -ne 0 ]; then
echo "❌ 移动压缩包失败"
exit 1
fi

# 在模块目录中解压外层zip
unzip -q "$MODULE_DIR/$ZIP_FILE" -d.
if [ $? -ne 0 ]; then
echo "❌ 外层解压失败。"
exit 1
fi
echo "✅ 外层解压完成，文件夹: $TEMP_DIR"

# 3. 清理不需要的文件
echo "步骤 3/8: 清理临时文件..."
rm -rf "$MODULE_DIR/$ZIP_FILE"
echo "✅ 已删除外层压缩包"

# 4. 解压内层压缩包
echo "步骤 4/8: 解压内层文件..."

# 检查内层zip文件是否存在
if [ ! -f "$MODULE_DIR/$INNER_ZIP_PATH" ]; then
echo "❌ 内层压缩包不存在: $MODULE_DIR/$INNER_ZIP_PATH"
exit 1
fi

# 在模块目录中解压内层zip
unzip -q "$MODULE_DIR/$INNER_ZIP_PATH" -d /data/adb/modules/wangke/wangke-main/
if [ $? -ne 0 ]; then
echo "❌ 内层解压失败。"
exit 1
fi
echo "✅ 内层解压完成"

# 5. 清理内层压缩包和README.md
echo "步骤 5/8: 清理内层文件..."
rm -rf "$MODULE_DIR/$INNER_ZIP_PATH"
rm -rf "$MODULE_DIR/$EXTRACT_DIR/README.md"
echo "✅ 已删除内层压缩包和README.md"

# 6.移动文件
echo "步骤 6/8: 移动文件..."
mv /data/adb/modules/wangke/wangke-main/* /data/adb/modules/wangke/ 2>/dev/null
# 移动整个文件夹
mv /data/adb/modules/wangke/wangke-main/webroot/* /data/adb/modules/wangke/webroot/ 2>/dev/null
rm -rf " /data/adb/modules/wangke/wangke-main"
# 7. 设置文件权限
echo "步骤 7/8: 设置文件权限..."
chmod 777 $MODULE_DIR/*.sh 2>/dev/null && echo "✅ 权限设置完成"

# 8. 最终检查
echo "步骤 8/8: 最终检查..."
if [ -f "$MODULE_DIR/module.prop" ] || [ $(ls -la $MODULE_DIR | wc -l) -gt 3 ]; then
echo "✅ 模块文件已成功安装到: $MODULE_DIR"
else
echo "⚠️  模块目录为空或缺少文件，请检查下载源"
fi
echo "🎉 所有操作已完成！"
}
main
