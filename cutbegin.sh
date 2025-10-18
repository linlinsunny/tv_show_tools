#!/bin/bash

# 视频开头剪切脚本 - 切除指定时间点之前的内容
# 使用方式：./video_trim_start.sh 输入视频文件

# 检查是否提供了输入文件
if [ $# -eq 0 ]; then
    echo "错误：请指定输入视频文件"
    echo "使用方法: $0 输入视频文件"
    exit 1
fi

input_file="$1"

# 检查输入文件是否存在
if [ ! -f "$input_file" ]; then
    echo "错误：文件 '$input_file' 不存在"
    exit 1
fi

# 获取文件名和扩展名
filename=$(basename -- "$input_file")
extension="${filename##*.}"
filename_noext="${filename%.*}"

# 设置输出文件名
output_file="${filename_noext}_trimmed_start.${extension}"

# 提示用户输入剪切时间点
echo "视频文件: $input_file"
echo "请输入要切除的开头部分时长（格式: mm:ss 或 hh:mm:ss）"
echo "示例: 01:30 或 00:01:30（表示切除前1分30秒）"
read -p "切除时长: " cut_duration

# 验证时间格式（支持 mm:ss 或 hh:mm:ss）
if ! [[ "$cut_duration" =~ ^([0-9]+:)?[0-9]+:[0-9]+$ ]]; then
    echo "错误：时间格式不正确，请使用 mm:ss 或 hh:mm:ss 格式"
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

echo "开始处理视频..."
echo "输入文件: $input_file"
echo "输出文件: $output_file"
echo "切除开头时长: $cut_duration"

# 使用 ffmpeg 进行剪切（从指定时间点开始保留）
ffmpeg -i "$input_file" -ss "$cut_duration" -c copy "$output_file"

# 检查 ffmpeg 执行结果
if [ $? -eq 0 ]; then
    echo "视频剪切完成！"
    echo "输出文件: $output_file"
    
    # 显示原始文件和输出文件的大小
    original_size=$(du -h "$input_file" | cut -f1)
    new_size=$(du -h "$output_file" | cut -f1)
    echo "原始文件大小: $original_size"
    echo "新文件大小: $new_size"
    
    # 显示视频时长信息（可选）
    if command -v ffprobe &> /dev/null; then
        original_duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$input_file" 2>/dev/null | cut -d. -f1)
        new_duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$output_file" 2>/dev/null | cut -d. -f1)
        
        if [ -n "$original_duration" ] && [ -n "$new_duration" ]; then
            orig_min=$((original_duration / 60))
            orig_sec=$((original_duration % 60))
            new_min=$((new_duration / 60))
            new_sec=$((new_duration % 60))
            echo "原始视频时长: ${orig_min}分${orig_sec}秒"
            echo "新视频时长: ${new_min}分${new_sec}秒"
        fi
    fi
else
    echo "错误：视频处理失败"
    exit 1
fi
