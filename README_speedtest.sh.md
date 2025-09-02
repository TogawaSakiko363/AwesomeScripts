# Dual-Ended HTTP Throughput Test Script

A simple yet powerful self-contained `bash` script for testing network throughput between two machines over HTTP. The script wraps a multi-threaded Python implementation that can operate in either a server or a client mode, handling its own dependencies.

This script is ideal for network administrators, developers, or anyone needing a quick and easy way to measure network performance between two points without installing complex software like iperf.

## Features

- **All-in-One**: A single script file (`speedtest.sh`) provides both server and client functionality.
- **Dependency-Free Start**: Automatically checks for and installs `python3`, `pip`, and required libraries (`requests`, `matplotlib`, `numpy`).
- **Bidirectional Testing**: Measure both upload (client-to-server) and download (server-to-client) speeds.
- **Multi-Threaded**: Utilizes multiple concurrent connections to saturate the network link for more accurate results.
- **Graphical Results**: The client generates a `speed_curve.png` chart to visualize network performance and stability over time.
- **Cross-Platform**: Compatible with most Linux distributions that use `apt`, `yum`, or `dnf` package managers.

## Prerequisites

- A `bash` shell.
- A Linux-based OS with `sudo` access to allow for the automatic installation of dependencies.
- Network connectivity between the two machines (server and client).

## Installation

1.  Download the script to both the server and client machines.

    ```bash
wget -O speedtest.sh https://raw.githubusercontent.com/TogawaSakiko363/AwesomeScripts/main/speedtest.sh/combo.sh
    ```

2.  Make the script executable:

    ```bash
    chmod +x speedtest.sh
    ```

## Usage

The script operates in two modes: `server` and `client`. You must first start the script in server mode on one machine, and then run it in client mode on another machine to perform the test.

---

### Running the Server

Start the script in server mode on the machine that will act as the test endpoint. It will listen for incoming connections from the client.

**Command:**

```bash
./speedtest.sh --mode server --listen 0.0.0.0:8080
```

**Explanation:**
- `--mode server`: Specifies that the script should run as a server.
- `--listen 0.0.0.0:8080`: Tells the server to listen on all available network interfaces (`0.0.0.0`) on port `8080`. You can change the port if needed.

The server will remain active until you stop it with `Ctrl+C`.

> **Note:** Ensure that your firewall on the server machine allows incoming TCP traffic on the port you are using (e.g., `8080`).

---

### Running the Client

On a separate machine, run the script in client mode to connect to the server and initiate the speed test.

#### **1. Testing Download Speed (Server to Client)**

To measure the speed of data being sent **from** the server **to** the client, use the `--Reverse` flag.

**Command:**

```bash
./speedtest.sh --mode client --server <SERVER_IP>:8080 --time 15s --threads 8 --Reverse
```

**Example:** If your server's IP is `192.168.1.100`:
```bash
./speedtest.sh --mode client --server 192.168.1.100:8080 --time 15s --threads 8 --Reverse
```

#### **2. Testing Upload Speed (Client to Server)**

To measure the speed of data being sent **from** the client **to** the server, simply omit the `--Reverse` flag. This is the default test direction.

**Command:**

```bash
./speedtest.sh --mode client --server <SERVER_IP>:8080 --time 15s --threads 8
```

**Example:** If your server's IP is `192.168.1.100`:
```bash
./speedtest.sh --mode client --server 192.168.1.100:8080 --time 15s --threads 8
```

#### Client Arguments

| Argument | Description | Example |
| :--- | :--- | :--- |
| **`--mode client`** | (Required) Specifies that the script should run as a client. | |
| **`--server <IP:Port>`** | (Required) The IP address and port of the machine running the server. | `--server 192.168.1.100:8080` |
| **`--time <duration>`** | The duration of the test. Use `s` for seconds and `m` for minutes. | `--time 10s` or `--time 1m`|
| **`--threads <number>`** | The number of concurrent threads (connections) to use for the test. | `--threads 4` |
| **`--Reverse`** | A flag that reverses the test direction to measure **download speed**. If omitted, it measures **upload speed**. | `--Reverse` |


### Example Output

After the client test is complete, you will see a summary in your terminal:

```
==============================
      Speed Test Results
==============================
  Average Speed: 850.34 Mbps
  Peak Speed   : 912.55 Mbps
==============================
[*] Speed curve graph saved to 'speed_curve.png'
```

Additionally, a file named `speed_curve.png` will be created in the same directory, providing a visual representation of the network speed throughout the test.

## License

This project is licensed under the MIT License.
