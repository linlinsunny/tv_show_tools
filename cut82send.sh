#!/usr/bin/env bash
# 切除当前文件夹所有视频最后 82 秒（浮点安全）
for f in *.{mp4,mkv,mov,avi}; do
  [[ -e $f ]] || continue
  dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f")
  # 用 awk 做浮点比较
  if awk -v d="$dur" 'BEGIN{exit !(d > 82)}'; then
    end=$(awk -v d="$dur" 'BEGIN{printf "%.3f", d-82}')
    out="${f%.*}_trim82.${f##*.}"
    echo "处理 $f  保留 0 ~ ${end}s"
    ffmpeg -i "$f" -to "$end" -c copy -avoid_negative_ts make_zero -y "$out"
  else
    echo "跳过 $f （不足 82 秒）"
  fi
done
echo "全部完成！"

