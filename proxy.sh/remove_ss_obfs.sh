#!/bin/bash

sudo systemctl stop shadowsocks-libev
sudo systemctl disable shadowsocks-libev
sudo apt remove shadowsocks-libev simple-obfs
