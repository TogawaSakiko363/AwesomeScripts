#!/bin/bash

# 更新系统
sudo apt update -y && sudo apt upgrade -y

# 安装必要的依赖
sudo apt install -y curl wget lsb-release unzip build-essential libssl-dev

# 安装 shadowsocks-rust
echo "正在安装 Shadowsocks-Rust..."
cd /usr/local/bin/
wget https://github.com/shadowsocks/shadowsocks-rust/releases/download/v1.22.0/shadowsocks-v1.22.0.x86_64-unknown-linux-gnu.tar.xz
sudo tar -xvf shadowsocks-v1.22.0.x86_64-unknown-linux-gnu.tar.xz
sudo rm -f shadowsocks-v1.22.0.x86_64-unknown-linux-gnu.tar.xz
sudo chmod +x /usr/local/bin/ssserver

# 安装 v2ray-plugin
echo "正在安装 v2ray-plugin..."
cd /usr/local/bin/
wget https://github.com/shadowsocks/v2ray-plugin/releases/download/v1.3.2/v2ray-plugin-linux-amd64-v1.3.2.tar.gz
sudo tar -xvzf v2ray-plugin-linux-amd64-v1.3.2.tar.gz
sudo rm -f v2ray-plugin-linux-amd64-v1.3.2.tar.gz
sudo mv v2ray-plugin_linux_amd64 v2ray-plugin
sudo chmod +x /usr/local/bin/v2ray-plugin

# 创建 Shadowsocks 配置文件
echo "正在配置 Shadowsocks-Rust..."
cat > /etc/shadowsocks.json <<EOL
{
  "server": "0.0.0.0",
  "server_port": 8080,
  "password": "+hU4fFunrxE7sm8zZdAmuA==",
  "method": "2022-blake3-aes-128-gcm",
  "plugin": "v2ray-plugin",
  "plugin_opts": "server"
  }
EOL

# 创建 systemd 服务
echo "正在配置 systemd 服务..."
cat > /etc/systemd/system/shadowsocks-rust.service <<EOL
[Unit]
Description=Shadowsocks Rust Server
After=network.target

[Service]
ExecStart=/usr/local/bin/ssserver -c /etc/shadowsocks.json
Restart=on-failure
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOL

# 重新加载 systemd 并启动 Shadowsocks 服务
echo "启动 Shadowsocks-Rust 服务..."
sudo systemctl daemon-reload
sudo systemctl enable shadowsocks-rust
sudo systemctl start shadowsocks-rust

# 检查服务状态
sudo systemctl status shadowsocks-rust

echo "Shadowsocks-Rust 和 v2ray-plugin 已成功部署并启动！"
