#!/bin/bash

# 停止并禁用 sing-box 服务
sudo systemctl stop sing-box
sudo systemctl disable sing-box

# 删除 sing-box 服务文件
sudo rm -f /etc/systemd/system/sing-box.service

# 删除 sing-box 二进制文件
sudo rm -f /usr/local/bin/sing-box

# 删除 sing-box 配置文件
sudo rm -rf /etc/sing-box

# 卸载 Go 环境
sudo rm -rf /usr/local/go

# 卸载依赖
sudo apt-get remove --purge -y curl wget unzip
sudo apt-get autoremove -y

# 清理系统
sudo apt-get clean
sudo rm -f go1.20.7.linux-amd64.tar.gz

echo "sing-box 和相关依赖已成功卸载。"
