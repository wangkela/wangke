#!/system/bin/sh
# 定义变量
DOWNLOAD_URL="https://github.com/wangkela/wangke/archive/refs/heads/main.zip"
ZIP_FILE="main.zip"
EXTRACT_DIR="wangke-main"
MODULE_DIR="/data/adb/modules/wangke"
TOTAL_SIZE=247388  # 总文件大小

# 清理旧的模块文件和文件夹
rm -rf $MODULE_DIR/$ZIP_FILE
rm -rf $MODULE_DIR/wangke-main

# 确保模块目录存在
mkdir -p $MODULE_DIR

# 进度变量
last_percentage=-1

main() {
# 1. 下载压缩包
echo "步骤 1/6: 开始下载文件..."

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

# 2. 解压压缩包
echo "步骤 2/6: 解压文件..."

# 检查是否安装了 unzip
if ! command -v unzip &> /dev/null; then
echo "❌ 需要安装 'unzip' 工具。"
echo "   请尝试执行: sudo apt-get install unzip 或 brew install unzip"
exit 1
fi

unzip -q "$ZIP_FILE" -d .

if [ $? -ne 0 ]; then
echo "❌ 解压失败。"
exit 1
fi
echo "✅ 解压完成，文件夹: $EXTRACT_DIR"

# 3. 移动文件到模块目录
echo "步骤 3/6: 移动文件到模块目录..."
if [ -d "$EXTRACT_DIR" ]; then
# 移动所有文件到模块目录
mv $EXTRACT_DIR/* $MODULE_DIR/ 2>/dev/null

if [ $? -eq 0 ]; then
echo "✅ 文件已移动到: $MODULE_DIR"
else
echo "❌ 移动文件失败"
exit 1
fi
else
echo "❌ 解压文件夹不存在: $EXTRACT_DIR"
exit 1
fi

# 4. 清理临时文件
echo "步骤 4/6: 清理临时文件..."
if [ -f "$ZIP_FILE" ]; then
rm "$ZIP_FILE"
echo "✅ 已删除压缩包: $ZIP_FILE"
fi
if [ -d "$EXTRACT_DIR" ]; then
rm -rf "$EXTRACT_DIR"
echo "✅ 已删除解压文件夹: $EXTRACT_DIR"
fi

# 5. 设置文件权限
echo "步骤 5/6: 设置文件权限..."
chmod 777 $MODULE_DIR/*.sh 2>/dev/null && echo "✅ 权限设置完成"

# 6. 最终检查
echo "步骤 6/6: 最终检查..."
if [ -f "$MODULE_DIR/module.prop" ] || [ $(ls -la $MODULE_DIR | wc -l) -gt 3 ]; then
echo "✅ 模块文件已成功安装到: $MODULE_DIR"
else
echo "⚠️  模块目录为空或缺少文件，请检查下载源"
fi
rm -rf "/data/adb/modules/wangke/README.md"
echo "🎉 所有操作已完成！"
}
main
