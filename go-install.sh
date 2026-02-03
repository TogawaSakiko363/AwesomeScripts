#!/bin/bash
set -e

# ================== 配置 ==================
GO_INSTALL_DIR="/usr/local"
TMP_DIR="/tmp/go-install"
PROFILE_FILES=("$HOME/.profile" "$HOME/.bashrc")

# ================== 依赖检查 ==================
for cmd in curl tar uname; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "❌ 缺少依赖: $cmd"
        exit 1
    fi
done

# ================== 架构判断 ==================
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)
        GO_ARCH="amd64"
        ;;
    aarch64|arm64)
        GO_ARCH="arm64"
        ;;
    *)
        echo "❌ 不支持的架构: $ARCH"
        exit 1
        ;;
esac

echo "✅ 检测到系统架构: $ARCH → Go 架构: $GO_ARCH"

# ================== 获取最新版本 ==================
echo "🔍 获取最新 Go 版本..."
LATEST_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -n 1)

GO_TARBALL="${LATEST_VERSION}.linux-${GO_ARCH}.tar.gz"
GO_URL="https://go.dev/dl/${GO_TARBALL}"

echo "📦 最新版本: $LATEST_VERSION"
echo "⬇️  下载地址: $GO_URL"

# ================== 清理旧版本 ==================
if [ -d "$GO_INSTALL_DIR/go" ]; then
    echo "🧹 移除旧版本 Go..."
    sudo rm -rf "$GO_INSTALL_DIR/go"
fi

# ================== 下载并安装 ==================
mkdir -p "$TMP_DIR"
cd "$TMP_DIR"

echo "⬇️  开始下载..."
curl -fLO "$GO_URL"

echo "📂 解压并安装..."
sudo tar -C "$GO_INSTALL_DIR" -xzf "$GO_TARBALL"

# ================== 配置环境变量（持久化） ==================
for FILE in "${PROFILE_FILES[@]}"; do
    if [ ! -f "$FILE" ]; then
        touch "$FILE"
    fi

    if ! grep -q '/usr/local/go/bin' "$FILE"; then
        {
            echo ''
            echo '# === Go environment ==='
            echo 'export GOPATH=$HOME/go'
            echo 'export PATH=/usr/local/go/bin:$GOPATH/bin:$PATH'
        } >> "$FILE"
        echo "✅ 已写入环境变量: $FILE"
    fi
done

# ================== 当前 shell 立即生效 ==================
export GOPATH="$HOME/go"
export PATH="/usr/local/go/bin:$GOPATH/bin:$PATH"

# ================== 验证 ==================
echo "🎉 Go 安装完成！"
echo "👉 Go 路径: $(command -v go)"
go version

# ================== 清理 ==================
rm -rf "$TMP_DIR"
