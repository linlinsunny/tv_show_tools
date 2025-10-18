#!/usr/bin/env bash
# 切除当前目录所有视频前 90 秒，不转码
for f in *.{mp4,mkv,mov,avi}; do
  [[ -e $f ]] || continue          # 无匹配时跳过
  out="${f%.*}_cut90.${f##*.}"     # 生成 xxx_cut90.mp4
  echo "处理 $f → $out"
  ffmpeg -ss 91 -i "$f" -c copy -avoid_negative_ts make_zero -y "$out"
done
echo "全部完成！"

