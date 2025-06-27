#!/bin/bash

set -e

# 检测系统架构和平台
ARCH=$(uname -m)
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

case "$ARCH" in
  x86_64) ARCH="amd64" ;;
  aarch64 | arm64) ARCH="arm64" ;;
  *)
    echo "[ERROR] 不支持的架构: $ARCH"
    exit 1
    ;;
esac

install() {
  echo "[INFO] 安装必要工具..."
  sudo apt update -y && sudo apt install -y curl wget jq tar lsb-release

  echo "[INFO] 获取 sing-box 最新 pre-release 版本..."
  SING_BOX_API_URL="https://api.github.com/repos/SagerNet/sing-box/releases"
  SING_BOX_LATEST=$(curl -s "${SING_BOX_API_URL}" | jq -r '[.[] | select(.prerelease==true)][0]')
  SING_BOX_VERSION=$(echo "${SING_BOX_LATEST}" | jq -r .tag_name)
  SING_BOX_ASSET_URL=$(echo "${SING_BOX_LATEST}" | jq -r ".assets[] | select(.name | test(\"${OS}-${ARCH}\\.tar\\.gz\")) | .browser_download_url")
  SING_BOX_TAR=$(basename "${SING_BOX_ASSET_URL}")

  if [[ -z "$SING_BOX_ASSET_URL" ]]; then
    echo "[ERROR] 未找到匹配系统平台的二进制包 (${OS}-${ARCH})"
    exit 1
  fi

  echo "[INFO] 下载并安装 sing-box ${SING_BOX_VERSION}..."
  cd /tmp
  wget -q "${SING_BOX_ASSET_URL}" -O "${SING_BOX_TAR}"
  mkdir -p sing-box-temp
  tar -xzf "${SING_BOX_TAR}" -C sing-box-temp

  SINGBOX_BIN=$(find sing-box-temp -type f -name sing-box | head -n 1)
  if [ -z "$SINGBOX_BIN" ]; then
    echo "[ERROR] 未找到 sing-box 可执行文件，可能是下载或解压失败。"
    exit 1
  fi
  sudo mv "$SINGBOX_BIN" /usr/local/bin/sing-box
  sudo chmod +x /usr/local/bin/sing-box
  rm -rf "${SING_BOX_TAR}" sing-box-temp

  echo "[INFO] 写入配置文件..."
  sudo mkdir -p /etc/sing-box
  sudo tee /etc/sing-box/config.json > /dev/null <<EOL
{
  "log": {
    "disabled": false,
    "level": "info",
    "timestamp": true
  },
  "route": {
    "rules": [
      {
        "inbound": ["vless-in"],
        "outbound": "direct"
      }
    ]
  },
  "inbounds": [
    {
      "type": "vless",
      "tag": "vless-in",
      "listen": "::",
      "listen_port": 8443,
      "users": [
        {
          "uuid": "79e2d4b8-272d-46ea-a345-323d8c32e00d",
          "flow": "xtls-rprx-vision"
        }
      ],
      "tls": {
        "enabled": true,
        "server_name": "www.map.gov.hk",
        "reality": {
          "enabled": true,
          "handshake": {
            "server": "www.map.gov.hk",
            "server_port": 443
          },
          "private_key": "GMUgzFqcABXZ-4Th1Y7yFabPjk7cspk5ECxOl4JtiUM",
          "short_id": "0123456789abcdef"
        }
      }
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    }
  ]
}
EOL

  echo "[INFO] 创建 systemd 服务..."
  sudo tee /etc/systemd/system/sing-box.service > /dev/null <<EOL
[Unit]
Description=Sing-Box Service
After=network.target

[Service]
ExecStart=/usr/local/bin/sing-box run -c /etc/sing-box/config.json
Restart=on-failure
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOL

  echo "[INFO] 启动 sing-box 服务..."
  sudo systemctl daemon-reload
  sudo systemctl enable sing-box
  sudo systemctl restart sing-box

  echo "[✅] Sing-box ${SING_BOX_VERSION} 安装完成并已启动！"
}

uninstall() {
  echo "[INFO] 正在卸载 Sing-Box..."

  sudo systemctl stop sing-box || true
  sudo systemctl disable sing-box || true
  sudo rm -f /etc/systemd/system/sing-box.service
  sudo systemctl daemon-reload

  sudo rm -f /usr/local/bin/sing-box
  sudo rm -rf /etc/sing-box

  echo "[✅] Sing-Box 已完全卸载。"
}

case "$1" in
  install)
    install
    ;;
  uninstall)
    uninstall
    ;;
  *)
    echo "用法: $0 {install|uninstall}"
    exit 1
    ;;
esac
