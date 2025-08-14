#!/bin/bash

set -euo pipefail

# === 自定义变量 ===
DOMAIN=${DOMAIN:-"sglong.wechat.com"}
USER_PASSWORD=${USER_PASSWORD:-"YOUSHOULDREALLYUSESTRONGPASSWORD"}
LISTEN_PORT=${LISTEN_PORT:-11451}

ARCH=$(uname -m)
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

case "$ARCH" in
  x86_64) ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *)
    echo "[ERROR] 不支持的架构: $ARCH"
    exit 1
    ;;
esac

DEPENDENCIES="curl wget jq tar lsb-release openssl"

get_latest_version_and_url() {
  local channel=$1  # stable or prerelease
  local api_url="https://api.github.com/repos/SagerNet/sing-box/releases"
  local releases_json
  releases_json=$(curl -s "$api_url")

  if [[ "$channel" == "prerelease" ]]; then
    release=$(echo "$releases_json" | jq -r '[.[] | select(.prerelease==true)][0]')
  else
    release=$(echo "$releases_json" | jq -r '[.[] | select(.prerelease==false)][0]')
  fi

  local version
  version=$(echo "$release" | jq -r .tag_name)
  local regex="${OS}-${ARCH}\\.tar\\.gz"
  local asset_url
  asset_url=$(echo "$release" | jq -r --arg regex "$regex" '.assets[] | select(.name | test($regex)) | .browser_download_url')

  if [[ -z "$asset_url" ]]; then
    echo "[ERROR] 未找到匹配系统平台的二进制包 (${OS}-${ARCH})"
    exit 1
  fi

  echo "$version|$asset_url"
}

install() {
  local channel=${1:-stable}
  echo "[INFO] 安装必要工具: $DEPENDENCIES"
  sudo apt update -y
  sudo apt install -y $DEPENDENCIES

  echo "[INFO] 获取 sing-box $channel 版本信息..."
  IFS='|' read -r version asset_url < <(get_latest_version_and_url "$channel")
  echo "[INFO] 版本: $version"
  echo "[INFO] 下载链接: $asset_url"

  cd /tmp
  local tar_file
  tar_file=$(basename "$asset_url")
  wget -q "$asset_url" -O "$tar_file"

  mkdir -p sing-box-temp
  tar -xzf "$tar_file" -C sing-box-temp

  local bin_path
  bin_path=$(find sing-box-temp -type f -name sing-box | head -n1)
  if [[ -z "$bin_path" ]]; then
    echo "[ERROR] 未找到 sing-box 可执行文件"
    exit 1
  fi

  sudo mv "$bin_path" /usr/local/bin/sing-box
  sudo chmod +x /usr/local/bin/sing-box

  rm -rf "$tar_file" sing-box-temp

  echo "[INFO] 生成自签名证书..."
  sudo mkdir -p /root/certs
  sudo openssl ecparam -genkey -name prime256v1 -out /root/certs/private.key
  sudo openssl req -new -x509 -days 36500 \
    -key /root/certs/private.key \
    -out /root/certs/cert.pem \
    -subj "/CN=${DOMAIN}"

  echo "[INFO] 写入配置文件..."
  sudo mkdir -p /etc/sing-box
  sudo tee /etc/sing-box/config.json > /dev/null <<EOF
{
  "log": {
    "disabled": false,
    "level": "info",
    "timestamp": true
  },
  "route": {
    "rules": [
      {
        "inbound": ["anytls-in"],
        "outbound": "direct"
      }
    ]
  },
  "inbounds": [
    {
      "type": "anytls",
      "tag": "anytls-in",
      "listen": "::",
      "listen_port": ${LISTEN_PORT},
      "users": [
        {
          "name": "AUUUUUUUUUUUUUUU",
          "password": "${USER_PASSWORD}"
        }
      ],
      "padding_scheme": [],
      "tls": {
        "server_name": "${DOMAIN}",
        "enabled": true,
        "certificate_path": "/root/certs/cert.pem",
        "key_path": "/root/certs/private.key"
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
EOF

  echo "[INFO] 创建 systemd 服务..."
  sudo tee /etc/systemd/system/sing-box.service > /dev/null <<EOF
[Unit]
Description=Sing-Box Service
After=network.target

[Service]
ExecStart=/usr/local/bin/sing-box run -c /etc/sing-box/config.json
Restart=on-failure
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

  echo "[INFO] 启动 sing-box 服务..."
  sudo systemctl daemon-reload
  sudo systemctl enable --now sing-box

  echo "[✅] Sing-box $version 安装完成并已启动！"
}

update() {
  local channel=${1:-stable}
  echo "[INFO] 获取最新 $channel 版本..."
  IFS='|' read -r version asset_url < <(get_latest_version_and_url "$channel")
  echo "[INFO] 版本: $version"

  cd /tmp
  local tar_file
  tar_file=$(basename "$asset_url")
  wget -q "$asset_url" -O "$tar_file"

  mkdir -p sing-box-temp
  tar -xzf "$tar_file" -C sing-box-temp

  local bin_path
  bin_path=$(find sing-box-temp -type f -name sing-box | head -n1)
  if [[ -z "$bin_path" ]]; then
    echo "[ERROR] 未找到 sing-box 可执行文件"
    exit 1
  fi

  echo "[INFO] 停止 sing-box 服务..."
  sudo systemctl stop sing-box || true

  echo "[INFO] 替换二进制文件..."
  sudo mv "$bin_path" /usr/local/bin/sing-box
  sudo chmod +x /usr/local/bin/sing-box

  rm -rf "$tar_file" sing-box-temp

  echo "[INFO] 重启 sing-box 服务..."
  sudo systemctl daemon-reload
  sudo systemctl restart sing-box

  echo "[✅] Sing-box 已更新到版本 $version 并已重启服务！"
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

usage() {
  echo "用法: \$0 {install|update|uninstall} [stable|prerelease]"
  echo "  环境变量:"
  echo "    DOMAIN         证书域名 (默认: sglong.wechat.com)"
  echo "    USER_PASSWORD  用户密码 (默认: YOUSHOULDREALLYUSESTRONGPASSWORD)"
  echo "    LISTEN_PORT    监听端口 (默认: 11451)"
  exit 1
}

case "${1:-}" in
  install) install "${2:-stable}" ;;
  update) update "${2:-stable}" ;;
  uninstall) uninstall ;;
  *) usage ;;
esac
