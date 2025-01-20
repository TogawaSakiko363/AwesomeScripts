#!/bin/bash

# 更新系统
sudo apt update -y && sudo apt upgrade -y

# 安装必要的依赖
sudo apt install -y curl wget lsb-release unzip

# 安装 Go 环境
wget https://golang.org/dl/go1.20.7.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.20.7.linux-amd64.tar.gz
echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
source ~/.bashrc

# 下载并安装sing-box
cd /usr/local/bin
# 下载 sing-box 压缩包
wget https://github.com/SagerNet/sing-box/releases/download/v1.11.0-beta.23/sing-box-1.11.0-beta.23-linux-amd64.tar.gz
# 解压文件到当前目录，并将 sing-box 二进制文件直接放入 /usr/local/bin
sudo tar --strip-components=1 -xvzf sing-box-1.11.0-beta.23-linux-amd64.tar.gz
# 删除压缩包文件
sudo rm -f sing-box-1.11.0-beta.23-linux-amd64.tar.gz


# 创建sing-box配置目录
mkdir -p /etc/sing-box
cd /etc/sing-box

# 下载并配置与shadowsocks-libev一致的配置模板
cat > config.json <<EOL
{
  "log": {
    "disabled": false,
    "level": "info",
    "timestamp": true
  },
  "route": {
    "rules": [
      {
        "inbound": ["net-in"],
        "outbound": "direct"
      }
    ]
  },
  "inbounds": [
    {
      "type": "trojan",
      "tag": "net-in",
      "listen": "::",
      "listen_port": 8080,
      "sniff": true,
      "sniff_override_destination": true,
      "transport": {
        "type": "httpupgrade",
        "path": "/fetch"
      },
      "users": [
        {
          "password": "F74739B23AF5AD27"
        }
      ],
      "multiplex": {
        "enabled": true,
        "padding": false
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

# 设置权限
sudo chmod +x /usr/local/bin/sing-box

# 创建 systemd 服务
cat > /etc/systemd/system/sing-box.service <<EOL
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

# 重新加载 systemd 服务并启动 sing-box
sudo systemctl daemon-reload
sudo systemctl enable sing-box
sudo systemctl start sing-box

# 检查 sing-box 服务状态
sudo systemctl status sing-box

echo "Sing-box 服务已成功部署并启动！"
