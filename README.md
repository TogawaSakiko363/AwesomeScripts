# Some awesome scripts 

 ### sing-box based one-click script for AnyTLS + self-signed certificate
 
```bash
wget https://raw.githubusercontent.com/TogawaSakiko363/AwesomeScripts/refs/heads/main/proxy.sh/sing-box_anytls.sh && \
DOMAIN="sglong.wechat.com" USER_PASSWORD="YOUSHOULDREALLYUSESTRONGPASSWORD" LISTEN_PORT=11451 bash sing-box_anytls.sh install
```
  
`DOMAIN="sglong.wechat.com" USER_PASSWORD="YOUSHOULDREALLYUSESTRONGPASSWORD" LISTEN_PORT=11451` can be defined custom

 ### sing-box based one-click script for AnyTLS + Reality
 
```bash
wget https://raw.githubusercontent.com/TogawaSakiko363/AwesomeScripts/refs/heads/main/proxy.sh/sing-box_anytls_reality.sh && \
DOMAIN="www.cityline.com" USER_PASSWORD="A0B9C8D7E6F5" LISTEN_PORT=8443 bash sing-box_anytls_reality.sh install
```

`DOMAIN="www.cityline.com" USER_PASSWORD="A0B9C8D7E6F5" LISTEN_PORT=8443` can be defined custom

 ### sing-box based one-click script for AnyTLS + ACME SSL
 
```bash
wget https://raw.githubusercontent.com/TogawaSakiko363/AwesomeScripts/refs/heads/main/proxy.sh/sing-box_anytls_acme.sh && \
DOMAIN="example.com" USER_PASSWORD="A0B9C8D7E6F5" EMAIL="example@example.com" LISTEN_PORT=8443 bash sing-box_anytls_acme.sh install
```
`USER_PASSWORD="A0B9C8D7E6F5" LISTEN_PORT=8443` can be defined custom
`DOMAIN="example.com" EMAIL="example@example.com"` It must be a domain that has resolved the server IP address and a correct email address
