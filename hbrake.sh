#!/bin/bash

# HandBrake 字幕烧录脚本
# 将 MKV 文件中的字幕烧录到视频并转换为 MP4

# 检查是否提供了输入文件
if [ $# -eq 0 ]; then
    echo "错误：请指定输入 MKV 文件"
    echo "使用方法: $0 输入文件.mkv"
    exit 1
fi

input_file="$1"

# 检查输入文件是否存在
if [ ! -f "$input_file" ]; then
    echo "错误：文件 '$input_file' 不存在"
    exit 1
fi

# 检查文件扩展名
if [[ "${input_file##*.}" != "mkv" ]]; then
    echo "警告：输入文件不是 MKV 格式，但将继续处理..."
fi

# 检查 HandBrakeCLI 是否安装
if ! command -v HandBrakeCLI &> /dev/null; then
    echo "错误：未找到 HandBrakeCLI，请先安装 HandBrake"
    echo "Ubuntu/Debian: sudo apt install handbrake-cli"
    echo "macOS: brew install handbrake"
    echo "或从 https://handbrake.fr/downloads.php 下载"
    exit 1
fi

# 获取文件名（不含扩展名）
filename=$(basename -- "$input_file")
filename_noext="${filename%.*}"

# 设置输出文件名
output_file="${filename_noext}_burned.mp4"

# 显示输入文件信息
echo "输入文件: $input_file"
echo "输出文件: $output_file"

# 首先扫描文件以获取轨道信息
echo "正在扫描文件轨道信息..."
HandBrakeCLI -i "$input_file" --title 0 --scan 2>&1 | grep -E "(subtitle|Subtitle)"

# 显示可用的字幕轨道
echo ""
echo "可用的字幕轨道："
HandBrakeCLI -i "$input_file" --title 0 --scan 2>&1 | grep -A5 "subtitle tracks"

# 提示用户选择字幕轨道
echo ""
echo "请选择要烧录的字幕轨道（通常为 1, 2, 3...）"
echo "如果不知道，可以尝试常见的轨道号（如 1）"
read -p "字幕轨道号: " subtitle_track

# 验证输入是否为数字
if ! [[ "$subtitle_track" =~ ^[0-9]+$ ]]; then
    echo "错误：请输入有效的数字"
    exit 1
fi

# 检查输出文件是否已存在
if [ -f "$output_file" ]; then
    read -p "输出文件 '$output_file' 已存在，是否覆盖？(y/N): " overwrite
    if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
        echo "操作已取消"
        exit 0
    fi
    rm -f "$output_file"
fi

# 视频编码预设（可以根据需要调整）
read -p "选择视频质量预设 (1-标准, 2-高质量, 3-自定义) [默认1]: " quality_choice

case $quality_choice in
    2|"高质量")
        preset="--encoder x264 --quality 20"
        ;;
    3|"自定义")
        read -p "输入 x264 质量值 (18-25，越小质量越高): " custom_quality
        preset="--encoder x264 --quality ${custom_quality:-20}"
        ;;
    *)
        preset="--encoder x264 --quality 23"
        ;;
esac

echo "开始烧录字幕并转换格式..."
echo "这可能需要一些时间，请耐心等待..."

# 执行 HandBrake 转换
HandBrakeCLI -i "$input_file" \
    -o "$output_file" \
    --format mp4 \
    $preset \
    --audio-lang-list eng,jpn,chi --all-audio \
    --subtitle "$subtitle_track" --subtitle-burn "$subtitle_track" \
    --decomb \
    --loose-anamorphic \
    --modulus 2 \
    --maxWidth 1920 --maxHeight 1080

# 检查执行结果
if [ $? -eq 0 ] && [ -f "$output_file" ]; then
    echo ""
    echo "转换完成！"
    echo "输出文件: $output_file"
    
    # 显示文件大小信息
    original_size=$(du -h "$input_file" | cut -f1)
    new_size=$(du -h "$output_file" | cut -f1)
    echo "原始文件大小: $original_size"
    echo "新文件大小: $new_size"
else
    echo "错误：转换失败"
    exit 1
fi
