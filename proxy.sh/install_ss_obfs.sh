#!/bin/bash

set -e

# 定义配置变量
SS_PORT=8080
SS_PASSWORD="0D5D97A426042033"
SS_METHOD="aes-128-gcm"


# 更新系统并安装必要的软件
apt update && apt upgrade -y
apt install -y shadowsocks-libev simple-obfs

# 配置 Shadowsocks
SS_CONFIG="/etc/shadowsocks-libev/config.json"
cat > $SS_CONFIG << EOF
{
    "server": "0.0.0.0",
    "server_port": $SS_PORT,
    "password": "$SS_PASSWORD",
    "timeout": 300,
    "method": "$SS_METHOD",
    "plugin": "obfs-server",
    "fast_open": true,
    "mode": "tcp_and_udp",
    "plugin_opts": "obfs=http"
}
EOF

# 设置 Shadowsocks 开机启动
systemctl enable shadowsocks-libev

# 启动 Shadowsocks 服务
systemctl restart shadowsocks-libev

# 检查服务状态
systemctl status shadowsocks-libev --no-pager

# 输出配置信息
echo "========================================"
echo "Shadowsocks 已安装并运行！"
echo "配置如下："
echo "服务器地址: $(hostname -I | awk '{print $1}')"
echo "服务器端口: $SS_PORT"
echo "密码: $SS_PASSWORD"
echo "加密方法: $SS_METHOD"
echo "Obfs 模式: http"
echo "========================================"
