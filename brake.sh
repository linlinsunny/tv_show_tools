#!/usr/bin/env bash
#  Apple Silicon  VideotoolBox 硬编 + 烧录字幕
for i in $(printf '%02d ' {1..26}); do
  echo "====== VTB 烧录 ${i}c.mkv → ${i}.mp4 ======"
  ffmpeg -hwaccel videotoolbox \
         -i "${i}c.mkv" \
         -vf subtitles="${i}c.mkv:si=1" \
         -c:v h264_videotoolbox -b:v 8M \
         -c:a copy "${i}.mp4"
done
echo "全部完成！"
