# Some awesome scripts 

## For technical exchange and learning only, please abide by the laws of your country and do not use it for illegal purposes.

 ### sing-box based one-click script for AnyTLS + self-signed certificate
 
```bash
wget https://raw.githubusercontent.com/TogawaSakiko363/AwesomeScripts/refs/heads/main/proxy.sh/sing-box_anytls.sh && \
DOMAIN="sglong.wechat.com" USER_PASSWORD="YOUSHOULDREALLYUSESTRONGPASSWORD" LISTEN_PORT=11451 bash sing-box_anytls.sh install
```
  
`DOMAIN="sglong.wechat.com" USER_PASSWORD="YOUSHOULDREALLYUSESTRONGPASSWORD" LISTEN_PORT=11451` can be customized

 ### sing-box based one-click script for AnyTLS + Reality
 
```bash
wget https://raw.githubusercontent.com/TogawaSakiko363/AwesomeScripts/refs/heads/main/proxy.sh/sing-box_anytls_reality.sh && \
DOMAIN="www.cityline.com" USER_PASSWORD="A0B9C8D7E6F5" LISTEN_PORT=8443 bash sing-box_anytls_reality.sh install
```

`DOMAIN="www.cityline.com" USER_PASSWORD="A0B9C8D7E6F5" LISTEN_PORT=8443` can be customized

 ### sing-box based one-click script for AnyTLS + ACME + Let's Encrypt SSL
 
```bash
wget https://raw.githubusercontent.com/TogawaSakiko363/AwesomeScripts/refs/heads/main/proxy.sh/sing-box_anytls_acme.sh && \
DOMAIN="example.com" USER_PASSWORD="A0B9C8D7E6F5" EMAIL="example@example.com" LISTEN_PORT=8443 bash sing-box_anytls_acme.sh install
```
`USER_PASSWORD="A0B9C8D7E6F5" LISTEN_PORT=8443` can be customized

`DOMAIN="example.com" EMAIL="example@example.com"` It must be a domain that has resolved the server IP address and a correct email address

 ### shadowsocks libev\rust + v2ray-plugin\obfs-server\none all in boom one-click script

 ```bash
wget https://raw.githubusercontent.com/TogawaSakiko363/AwesomeScripts/refs/heads/main/proxy.sh/shadowsocks.sh && \
VERSION=rust LISTEN=0.0.0.0 PORT=8080 PLUGIN=obfs-server PASSWORD=+hU4fFunrxE7sm8zZdAmuA== METHOD=2022-blake3-aes-128-gcm bash shadowsocks.sh install 
```

`VERSION=rust` or `VERSION=libev`

`PLUGIN=obfs-server` or `PLUGIN=v2ray-plugin` or `PLUGIN=false`

`LISTEN=0.0.0.0 PORT=8080 PASSWORD=+hU4fFunrxE7sm8zZdAmuA== METHOD=2022-blake3-aes-128-gcm` can be customized

 ### Python3 based temporary HTTP Speedtest Server script

Server:
  ```bash
wget https://raw.githubusercontent.com/TogawaSakiko363/AwesomeScripts/refs/heads/main/speedtest.sh/server.sh && \
bash server.sh --port 8080 --size 100MB
```

Client:
  ```bash
wget https://raw.githubusercontent.com/TogawaSakiko363/AwesomeScripts/refs/heads/main/speedtest.sh/client.sh && \
bash client.sh --server http://<server_ip>:8080/100MB.bin
```

`--port 8080 --size 100MB` can be customized


