#!/bin/bash

set -euo pipefail

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

DEPENDENCIES="curl wget jq tar lsb-release"

get_latest_version_and_url() {
  local channel=$1  # stable or prerelease
  local api_url="https://api.github.com/repos/SagerNet/sing-box/releases"
  local releases_json
  releases_json=$(curl -s "$api_url")

  if [[ "$channel" == "prerelease" ]]; then
    # 取第一个 prerelease
    release=$(echo "$releases_json" | jq -r '[.[] | select(.prerelease==true)][0]')
  else
    # 取第一个非 prerelease（即稳定版）
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

  echo "[INFO] 写入配置文件..."
  sudo mkdir -p /etc/sing-box
  sudo tee /etc/sing-box/config.json > /dev/null <<'EOF'
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
  echo "用法: $0 {install|update|uninstall} [stable|prerelease]"
  echo "  install: 安装 sing-box，默认 stable 通道"
  echo "  update: 更新 sing-box，默认 stable 通道"
  echo "  uninstall: 卸载 sing-box"
  exit 1
}

case "${1:-}" in
  install) install "${2:-stable}" ;;
  update) update "${2:-stable}" ;;
  uninstall) uninstall ;;
  *) usage ;;
esac
