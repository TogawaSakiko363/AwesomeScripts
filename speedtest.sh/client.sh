#!/bin/bash

set -e

while [[ $# -gt 0 ]]; do
  case "$1" in
    --server)
      SERVER_URL="$2"
      shift 2
      ;;
    *)
      echo "未知参数: $1"
      exit 1
      ;;
  esac
done

if [[ -z "$SERVER_URL" ]]; then
  echo "用法: bash client.sh --server http://<ip>:<port>/<file>"
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 未安装，正在安装..."
  if command -v apt >/dev/null 2>&1; then
    sudo apt update && sudo apt install -y python3
  elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y python3
  else
    echo "请手动安装 python3"
    exit 1
  fi
fi

echo "开始测速: $SERVER_URL"

python3 - "$SERVER_URL" <<'PYCODE'
import sys, time, urllib.request

url = sys.argv[1]

req = urllib.request.urlopen(url)
total_size = int(req.headers.get('Content-Length', 0))

start = time.time()
downloaded = 0
last_time = start
last_downloaded = 0
speeds = []

chunk_size = 1024*256
while True:
    chunk = req.read(chunk_size)
    if not chunk:
        break
    downloaded += len(chunk)
    now = time.time()
    if now - last_time >= 1:
        interval = now - last_time
        bytes_in_interval = downloaded - last_downloaded
        speed_bps = bytes_in_interval / interval
        speeds.append(speed_bps)
        last_time = now
        last_downloaded = downloaded

end = time.time()
duration = end - start
if duration <= 0:
    duration = 1

avg_speed_mbps = (downloaded * 8 / duration) / (1024*1024)
peak_speed_mbps = (max(speeds) * 8) / (1024*1024) if speeds else avg_speed_mbps

print("测速完成")
print(f"平均速度: {avg_speed_mbps:.2f} Mbps")
print(f"峰值速度: {peak_speed_mbps:.2f} Mbps")
PYCODE
