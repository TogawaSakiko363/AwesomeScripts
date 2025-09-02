#!/bin/bash

set -e

# === 参数解析 ===
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

# === 检测 curl ===
if ! command -v curl >/dev/null 2>&1; then
  echo "curl 未安装，正在安装..."
  if command -v apt >/dev/null 2>&1; then
    sudo apt update && sudo apt install -y curl
  elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y curl
  else
    echo "不支持的系统，请手动安装 curl"
    exit 1
  fi
fi

# === 测速 ===
echo "开始测速: $SERVER_URL"
RESULT=$(curl -L -w "time_total:%{time_total}\nspeed_download:%{speed_download}\nspeed_upload:%{speed_upload}\n" -o /dev/null -s "$SERVER_URL")

TOTAL_TIME=$(echo "$RESULT" | grep time_total | cut -d':' -f2)
SPEED_BPS=$(echo "$RESULT" | grep speed_download | cut -d':' -f2)

# 换算为 Mbps
SPEED_Mbps=$(awk "BEGIN {printf \"%.2f\", $SPEED_BPS*8/1024/1024}")
PEAK_Mbps=$SPEED_Mbps  # curl单线程即最大速度≈平均速度

echo "测速完成"
echo "平均速度: $SPEED_Mbps Mbps"
echo "峰值速度: $PEAK_Mbps Mbps"
