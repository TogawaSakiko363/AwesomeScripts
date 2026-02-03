# Some awesome scripts 

 ### Python3 based temporary HTTP Speedtest script

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


