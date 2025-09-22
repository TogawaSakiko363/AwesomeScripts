#!/bin/bash

set -e

# === 配置 ===
GO_INSTALL_DIR="/usr/local"
PROFILE_FILE="$HOME/.profile"
TMP_DIR="/tmp/go-install"

# 检查依赖
command -v curl >/dev/null 2>&1 || { echo "请先安装 curl：sudo apt update && sudo apt install curl"; exit 1; }
command -v tar >/dev/null 2>&1 || { echo "请先安装 tar：sudo apt install tar"; exit 1; }

# 获取最新版本号
echo "获取最新 Go 版本..."
LATEST_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -n 1)
GO_TARBALL="${LATEST_VERSION}.linux-amd64.tar.gz"
GO_URL="https://go.dev/dl/${GO_TARBALL}"

echo "最新版本为: $LATEST_VERSION"
echo "下载地址为: $GO_URL"

# 清理旧版本
if [ -d "$GO_INSTALL_DIR/go" ]; then
    echo "检测到旧版本，正在移除..."
    sudo rm -rf "$GO_INSTALL_DIR/go"
fi

# 创建临时目录并下载
mkdir -p "$TMP_DIR"
cd "$TMP_DIR"

echo "开始下载 Go 安装包..."
curl -LO "$GO_URL"

echo "解压并安装 Go..."
sudo tar -C "$GO_INSTALL_DIR" -xzf "$GO_TARBALL"

# 配置环境变量
if ! grep -q '/usr/local/go/bin' "$PROFILE_FILE"; then
    echo 'export PATH=$PATH:/usr/local/go/bin' >> "$PROFILE_FILE"
    echo 'export GOPATH=$HOME/go' >> "$PROFILE_FILE"
    echo 'export PATH=$PATH:$GOPATH/bin' >> "$PROFILE_FILE"
    echo "已将 Go 路径添加到 $PROFILE_FILE"
fi

# 加载环境变量（当前 shell 生效）
source "$PROFILE_FILE"

# 验证安装
echo "✅ Go 安装成功！当前版本："
go version

# 清理临时文件
rm -rf "$TMP_DIR"
