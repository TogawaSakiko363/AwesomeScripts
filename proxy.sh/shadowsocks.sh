#!/bin/bash
set -e

# 当执行 uninstall 时，跳过变量校验
if [ "$1" != "uninstall" ]; then
    [ -z "$VERSION" ] && echo "错误: 必须设置 VERSION=libev 或 VERSION=rust" && exit 1
    [ -z "$LISTEN" ] && echo "错误: 必须设置 LISTEN=监听地址" && exit 1
    [ -z "$PORT" ] && echo "错误: 必须设置 PORT=端口号" && exit 1
    [ -z "$PLUGIN" ] && echo "错误: 必须设置 PLUGIN=v2ray-plugin/obfs-server/false" && exit 1
    [ -z "$PASSWORD" ] && echo "错误: 必须设置 PASSWORD=密码" && exit 1
    [ -z "$METHOD" ] && echo "错误: 必须设置 METHOD=aes-128-gcm/2022-blake3-aes-128-gcm" && exit 1
fi

SERVICE_NAME="shadowsocks-${VERSION}"

show_status() {
    echo "========================================"
    echo "Shadowsocks 已安装并运行！"
    echo "服务器地址: $(hostname -I | awk '{print $1}')"
    echo "监听地址:   $LISTEN"
    echo "端口:       $PORT"
    echo "密码:       $PASSWORD"
    echo "加密方式:   $METHOD"
    echo "插件:       $PLUGIN"
    echo "========================================"

    if [ "$VERSION" == "libev" ]; then
        systemctl --no-pager status shadowsocks-libev || true
    else
        systemctl --no-pager status $SERVICE_NAME || true
    fi
}

install_libev() {
    echo "=== 安装 Shadowsocks-libev ==="
    apt update && apt upgrade -y
    apt install -y shadowsocks-libev

    # 安装插件（如需要）
    if [ "$PLUGIN" == "obfs-server" ]; then
        apt install -y simple-obfs
    elif [ "$PLUGIN" == "v2ray-plugin" ]; then
        apt install -y v2ray-plugin
    fi

    mkdir -p /etc/shadowsocks-libev
    cat > /etc/shadowsocks-libev/config.json <<EOF
{
    "server": "$LISTEN",
    "server_port": $PORT,
    "password": "$PASSWORD",
    "timeout": 300,
    "method": "$METHOD",
    "fast_open": true,
    "mode": "tcp_and_udp"$( [ "$PLUGIN" != "false" ] && echo ",\"plugin\": \"$PLUGIN\",\"plugin_opts\": \"server\"" )
}
EOF

    systemctl enable shadowsocks-libev
    systemctl restart shadowsocks-libev
    show_status
}

install_rust() {
    echo "=== 安装 Shadowsocks-Rust ==="
    apt update && apt upgrade -y
    apt install -y curl wget lsb-release unzip build-essential libssl-dev

    cd /usr/local/bin/
    wget https://github.com/shadowsocks/shadowsocks-rust/releases/download/v1.22.0/shadowsocks-v1.22.0.x86_64-unknown-linux-gnu.tar.xz
    tar -xvf shadowsocks-v1.22.0.x86_64-unknown-linux-gnu.tar.xz
    rm -f shadowsocks-v1.22.0.x86_64-unknown-linux-gnu.tar.xz
    chmod +x /usr/local/bin/ssserver

    # 安装插件（如需要）
    if [ "$PLUGIN" == "v2ray-plugin" ]; then
        cd /usr/local/bin/
        wget https://github.com/shadowsocks/v2ray-plugin/releases/download/v1.3.2/v2ray-plugin-linux-amd64-v1.3.2.tar.gz
        tar -xvzf v2ray-plugin-linux-amd64-v1.3.2.tar.gz
        rm -f v2ray-plugin-linux-amd64-v1.3.2.tar.gz
        mv v2ray-plugin_linux_amd64 v2ray-plugin
        chmod +x /usr/local/bin/v2ray-plugin
    fi

    cat > /etc/shadowsocks.json <<EOF
{
  "server": "$LISTEN",
  "server_port": $PORT,
  "password": "$PASSWORD",
  "method": "$METHOD"$( [ "$PLUGIN" != "false" ] && echo ",\"plugin\": \"$PLUGIN\",\"plugin_opts\": \"server\"" )
}
EOF

    cat > /etc/systemd/system/shadowsocks-rust.service <<EOF
[Unit]
Description=Shadowsocks Rust Server
After=network.target

[Service]
ExecStart=/usr/local/bin/ssserver -c /etc/shadowsocks.json
Restart=on-failure
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable shadowsocks-rust
    systemctl restart shadowsocks-rust
    show_status
}

uninstall_all() {
    echo "=== 卸载 Shadowsocks 服务 ==="
    # 停止并禁用所有可能的服务
    systemctl stop shadowsocks-libev 2>/dev/null || true
    systemctl disable shadowsocks-libev 2>/dev/null || true
    systemctl stop shadowsocks-rust 2>/dev/null || true
    systemctl disable shadowsocks-rust 2>/dev/null || true

    # 删除配置文件与 systemd
    rm -f /etc/shadowsocks.json
    rm -rf /etc/shadowsocks-libev
    rm -f /etc/systemd/system/shadowsocks-rust.service

    # 清理软件包与二进制
    apt purge -y shadowsocks-libev simple-obfs v2ray-plugin 2>/dev/null || true
    rm -f /usr/local/bin/ssserver /usr/local/bin/v2ray-plugin

    systemctl daemon-reload
    echo "=== 卸载完成 ==="
}

case "$1" in
    install)
        if [ "$VERSION" == "libev" ]; then
            install_libev
        elif [ "$VERSION" == "rust" ]; then
            install_rust
        else
            echo "错误: VERSION 必须为 libev 或 rust"
            exit 1
        fi
        ;;
    uninstall)
        uninstall_all
        ;;
    *)
        echo "用法: bash $0 install|uninstall"
        ;;
esac
