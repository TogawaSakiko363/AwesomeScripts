#!/bin/bash

sudo systemctl stop shadowsocks-rust
sudo systemctl disable shadowsocks-rust
cd /usr/local/bin/
sudo rm -rf sslocal  ssmanager  ssserver  ssservice  ssurl	v2ray-plugin
cd 