#!/bin/bash

set -e

# === 参数解析 ===
while [[ $# -gt 0 ]]; do
  case "$1" in
    --port)
      PORT="$2"
      shift 2
      ;;
    --size)
      SIZE="$2"
      shift 2
      ;;
    *)
      echo "未知参数: $1"
      exit 1
      ;;
  esac
done

if [[ -z "$PORT" || -z "$SIZE" ]]; then
  echo "用法: bash server.sh --port <端口> --size <大小如100MB>"
  exit 1
fi

# === 检测 Python3 ===
if ! command -v python3 >/dev/null 2>&1; then
  echo "Python3 未安装，正在安装..."
  if command -v apt >/dev/null 2>&1; then
    sudo apt update && sudo apt install -y python3
  elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y python3
  else
    echo "不支持的系统，请手动安装 python3"
    exit 1
  fi
fi

# === 生成临时文件 ===
FILENAME=$(echo "$SIZE" | tr -d ' ')
TMPDIR=$(mktemp -d)
FILEPATH="$TMPDIR/$FILENAME.bin"
echo "正在生成 $FILEPATH ..."
head -c "$SIZE" </dev/urandom > "$FILEPATH"

# === 启动 HTTP 服务器 ===
echo "启动HTTP服务器: 端口 $PORT，文件大小 $SIZE"
cd "$TMPDIR"
trap 'echo "清理临时文件..."; rm -rf "$TMPDIR"' EXIT
python3 -m http.server "$PORT"
