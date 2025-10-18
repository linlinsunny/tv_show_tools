#!/bin/bash

# 修复版视频合并脚本 - 正确数字排序

# 检查 ffmpeg
if ! command -v ffmpeg &> /dev/null; then
    echo "请先安装 ffmpeg"
    exit 1
fi

# 查找当前目录的视频文件并按数字排序
echo "正在扫描视频文件..."
video_files=()
while IFS= read -r file; do
    [ -f "$file" ] && video_files+=("$file")
done < <(find . -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.avi" -o -iname "*.mov" \) | sed 's|^./||' | sort -n)

# 如果上面的排序不行，尝试另一种方法
if [ ${#video_files[@]} -eq 0 ]; then
    while IFS= read -r -d $'\0' file; do
        video_files+=("$file")
    done < <(find . -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.avi" -o -iname "*.mov" \) -print0)
    
    # 手动数字排序
    video_files=($(printf "%s\n" "${video_files[@]}" | sed 's|^./||' | sort -n))
fi

if [ ${#video_files[@]} -eq 0 ]; then
    echo "当前目录没有找到视频文件"
    exit 1
fi

echo "找到以下视频文件（按数字排序）:"
for i in "${!video_files[@]}"; do
    echo "$((i+1)). ${video_files[i]}"
done

echo ""
echo "请选择要合并的文件（输入数字，多个文件用空格分隔，或使用范围如 1-26）"
read -p "选择: " selection

# 处理用户选择
selected_files=()

# 处理范围选择（如 1-26）
if [[ "$selection" =~ ^[0-9]+-[0-9]+$ ]]; then
    start=${selection%-*}
    end=${selection#*-}
    echo "选择范围: $start 到 $end"
    for ((i=start; i<=end; i++)); do
        if [ $i -ge 1 ] && [ $i -le ${#video_files[@]} ]; then
            selected_files+=("${video_files[$((i-1))]}")
            echo "添加文件: ${video_files[$((i-1))]}"
        else
            echo "警告: 编号 $i 无效"
        fi
    done
else
    # 处理空格分隔的数字
    IFS=' ' read -ra numbers <<< "$selection"
    for num in "${numbers[@]}"; do
        if [[ "$num" =~ ^[0-9]+$ ]] && [ $num -ge 1 ] && [ $num -le ${#video_files[@]} ]; then
            selected_files+=("${video_files[$((num-1))]}")
        else
            echo "警告: 编号 $num 无效，已跳过"
        fi
    done
fi

if [ ${#selected_files[@]} -eq 0 ]; then
    echo "错误: 没有选择有效的文件"
    exit 1
fi

echo ""
echo "已选择以下文件进行合并:"
for i in "${!selected_files[@]}"; do
    echo "$((i+1)). ${selected_files[i]}"
done

# 确认合并顺序
read -p "是否按此顺序合并？(Y/n): " confirm
if [[ "$confirm" =~ ^[Nn]$ ]]; then
    echo "操作已取消"
    exit 0
fi

# 生成文件列表
file_list="concat_list.txt"
rm -f "$file_list"
for file in "${selected_files[@]}"; do
    echo "file '$file'" >> "$file_list"
done

# 设置输出文件名
output_file="merged_$(date +%Y%m%d_%H%M%S).mp4"

echo ""
echo "开始合并 ${#selected_files[@]} 个视频文件..."
echo "输出文件: $output_file"

# 使用 ffmpeg 进行合并
ffmpeg -f concat -safe 0 -i "$file_list" -c copy "$output_file"

if [ $? -eq 0 ] && [ -f "$output_file" ]; then
    echo "✅ 合并完成: $output_file"
else
    echo "❌ 合并失败"
    exit 1
fi

rm -f "$file_list"