#!/bin/bash

# ==============================================================================
#
#   Dual-ended HTTP Speed Test Script (speedtest.sh)
#
#   Description:
#   This script provides both a server and a client for testing network
#   throughput over HTTP. It checks for Python 3, Pip, and required
#   libraries, installing them if necessary. Handles modern Linux pip
#   restrictions when run as root.
#
#   Author: Gemini
#   Version: 1.1
#
# ==============================================================================

# --- Utility Functions ---
print_info() {
    echo "[INFO] $1"
}

print_error() {
    echo "[ERROR] $1" >&2
}

# --- Dependency Check and Installation ---
check_and_install_deps() {
    print_info "Checking dependencies..."

    # 1. Check for Python 3 and Pip
    PYTHON_OK=true
    PIP_OK=true
    if ! command -v python3 &> /dev/null; then
        PYTHON_OK=false
    fi
    if ! python3 -m pip --version &> /dev/null; then
        PIP_OK=false
    fi

    if [ "$PYTHON_OK" = false ] || [ "$PIP_OK" = false ]; then
        if [ "$PYTHON_OK" = false ]; then
            print_info "Python 3 not found."
        fi
        if [ "$PIP_OK" = false ]; then
            print_info "Pip for Python 3 not found."
        fi
        print_info "Attempting to install required system packages (python3, python3-pip)..."
        
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y python3 python3-pip
        elif command -v yum &> /dev/null; then
            sudo yum install -y python3 python3-pip
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y python3 python3-pip
        else
            print_error "Cannot determine package manager. Please install Python 3 and Pip for Python 3 manually."
            exit 1
        fi
        
        # Verify installation
        if ! command -v python3 &> /dev/null || ! python3 -m pip --version &> /dev/null; then
            print_error "Python 3 / Pip installation failed. Please install them manually."
            exit 1
        fi
        print_info "Python 3 and Pip installed successfully."
    else
        print_info "Python 3 and Pip are already installed."
    fi

    # 2. Check for Python libraries
    print_info "Checking required Python libraries (requests, matplotlib, numpy)..."
    if ! python3 -c "import requests, matplotlib, numpy" &> /dev/null; then
        print_info "Required Python libraries not found. Installing via pip..."
        
        # Base pip command
        PIP_INSTALL_CMD="python3 -m pip install"
        
        # If running as root, add --break-system-packages for modern distros (PEP 668)
        # This is necessary to allow pip to modify packages in root-owned environments.
        if [ "$(id -u)" -eq 0 ]; then
            print_info "Running as root. Appending --break-system-packages to pip command for compatibility."
            PIP_INSTALL_CMD="$PIP_INSTALL_CMD --break-system-packages"
        fi
        
        # Execute the installation
        $PIP_INSTALL_CMD requests matplotlib numpy
        
        if [ $? -ne 0 ]; then
            print_error "Failed to install Python libraries. Please check your pip configuration."
            exit 1
        fi
        print_info "Python libraries installed successfully."
    else
        print_info "All required Python libraries are already installed."
    fi
}


# --- Main Logic: Argument Parsing and Execution ---
main() {
    # Default values
    MODE=""
    LISTEN_ADDR="0.0.0.0:8080"
    SERVER_ADDR=""
    TEST_TIME="10s"
    THREADS=4
    REVERSE=false

    # Parse command line arguments
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --mode) MODE="$2"; shift ;;
            --listen) LISTEN_ADDR="$2"; shift ;;
            --server) SERVER_ADDR="$2"; shift ;;
            --time) TEST_TIME="$2"; shift ;;
            --threads) THREADS="$2"; shift ;;
            --Reverse) REVERSE=true ;;
            *) print_error "Unknown parameter passed: $1"; exit 1 ;;
        esac
        shift
    done

    if [ -z "$MODE" ]; then
        print_error "Usage: $0 --mode [server|client] [options]"
        print_error "Server: $0 --mode server --listen <ip:port>"
        print_error "Client: $0 --mode client --server <ip:port> [--time 10s] [--threads 4] [--Reverse]"
        exit 1
    fi

    # Create a temporary Python script file
    TMP_PY_SCRIPT=$(mktemp /tmp/speedtest.py.XXXXXX)
    trap 'rm -f "$TMP_PY_SCRIPT"' EXIT # Ensure cleanup on exit

    # Embed the Python script using a HERE document
    # Using 'EOF' with quotes to prevent shell variable expansion inside the Python code
    cat > "$TMP_PY_SCRIPT" << 'EOF'
import sys
import os
import time
import argparse
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import requests
import queue
import numpy as np
import matplotlib.pyplot as plt

# --- Shared Configuration ---
CHUNK_SIZE = 1024 * 64  # 64 KB
# Generate a chunk of random data once to be reused for uploads
RANDOM_CHUNK = os.urandom(CHUNK_SIZE)

# ==============================================================================
#
#   SERVER IMPLEMENTATION
#
# ==============================================================================
class SpeedTestHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        """Handler for download tests."""
        if self.path == '/download':
            self.send_response(200)
            self.send_header('Content-type', 'application/octet-stream')
            self.end_headers()
            try:
                while True:
                    self.wfile.write(RANDOM_CHUNK)
            except (ConnectionResetError, ConnectionAbortedError, BrokenPipeError):
                # Client has closed the connection, which is expected
                pass
            except Exception as e:
                print(f"[Server ERROR] GET: {e}")
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b'Not Found')

    def do_POST(self):
        """Handler for upload tests."""
        if self.path == '/upload':
            self.send_response(200)
            self.end_headers()
            try:
                # Read and discard all data from the client
                content_length = int(self.headers.get('Content-Length', 0))
                if content_length > 0:
                    read_bytes = 0
                    while read_bytes < content_length:
                        chunk = self.rfile.read(min(CHUNK_SIZE, content_length - read_bytes))
                        if not chunk:
                            break
                        read_bytes += len(chunk)
                else: # Streaming upload
                    while self.rfile.read(CHUNK_SIZE):
                        pass

            except (ConnectionResetError, ConnectionAbortedError, BrokenPipeError):
                 pass # Client has closed the connection
            except Exception as e:
                print(f"[Server ERROR] POST: {e}")
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        # Suppress the default logging to keep the output clean
        return

def run_server(listen_addr):
    host, port_str = listen_addr.split(':')
    port = int(port_str)
    server = ThreadingHTTPServer((host, port), SpeedTestHandler)
    print(f"[*] Server listening on http://{host}:{port}")
    print("[*] Ready to serve download (/download) and upload (/upload) tests.")
    print("[*] Press Ctrl+C to stop the server.")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[*] Shutting down server.")
        server.server_close()

# ==============================================================================
#
#   CLIENT IMPLEMENTATION
#
# ==============================================================================
class Client:
    def __init__(self, server, duration_s, threads, reverse):
        self.server = server
        self.duration = duration_s
        self.num_threads = threads
        self.reverse = reverse # True for download, False for upload
        self.test_active = True
        self.data_queue = queue.Queue() # Thread-safe queue to store (timestamp, bytes)

    def _upload_worker(self, url):
        """Worker thread for uploading data."""
        def data_generator():
            while self.test_active:
                self.data_queue.put((time.time(), len(RANDOM_CHUNK)))
                yield RANDOM_CHUNK
        
        try:
            with requests.post(url, data=data_generator(), stream=True, timeout=self.duration + 5) as r:
                # The request will run until the generator stops (test_active becomes False)
                # or server closes connection.
                pass
        except requests.exceptions.RequestException:
            # Expected when the test duration ends and the connection is cut.
            pass
        except Exception as e:
            print(f"[Thread ERROR] {e}")


    def _download_worker(self, url):
        """Worker thread for downloading data."""
        try:
            with requests.get(url, stream=True, timeout=self.duration + 5) as r:
                r.raise_for_status()
                for chunk in r.iter_content(chunk_size=CHUNK_SIZE):
                    if not self.test_active:
                        break
                    self.data_queue.put((time.time(), len(chunk)))
        except requests.exceptions.RequestException:
            # Expected when the test duration ends and the connection is cut.
            pass
        except Exception as e:
            print(f"[Thread ERROR] {e}")

    def run_test(self):
        """Starts and manages the speed test."""
        if not self.server.startswith(('http://', 'https://')):
            self.server = 'http://' + self.server

        if self.reverse:
            test_type = "Download"
            url = f"{self.server}/download"
            worker_func = self._download_worker
        else:
            test_type = "Upload"
            url = f"{self.server}/upload"
            worker_func = self._upload_worker

        print(f"[*] Starting {test_type} test to {self.server}")
        print(f"[*] Duration: {self.duration}s, Threads: {self.num_threads}")
        
        threads = []
        start_time = time.time()
        for _ in range(self.num_threads):
            thread = threading.Thread(target=worker_func, args=(url,))
            thread.daemon = True
            thread.start()
            threads.append(thread)
        
        # Let the test run for the specified duration
        time.sleep(self.duration)
        
        # Signal threads to stop
        self.test_active = False
        end_time = time.time()
        
        print("[*] Test finished. Waiting for threads to complete...")
        for thread in threads:
            thread.join(timeout=2) # Give threads a moment to finish

        print("[*] Calculating results...")
        self._process_results(start_time, end_time)

    def _process_results(self, start_time, end_time):
        """Analyzes data from the queue and prints results."""
        if self.data_queue.empty():
            print("\n[ERROR] No data was transferred. Check server connection and firewall.")
            return

        all_data = []
        while not self.data_queue.empty():
            all_data.append(self.data_queue.get())
        
        # Sort by timestamp
        all_data.sort(key=lambda x: x[0])
        
        total_bytes = sum(item[1] for item in all_data)
        actual_duration = end_time - start_time
        
        # Calculate Average Speed
        avg_speed_mbps = (total_bytes * 8) / (actual_duration * 1_000_000)

        # Calculate Peak Speed by binning data into 1-second intervals
        time_bins = np.arange(start_time, end_time, 1.0)
        bytes_per_second = np.zeros(len(time_bins))
        timestamps = np.array([d[0] for d in all_data])
        byte_counts = np.array([d[1] for d in all_data])

        for i, bin_start in enumerate(time_bins):
            bin_end = bin_start + 1.0
            # Find indices of data points within this time bin
            indices = np.where((timestamps >= bin_start) & (timestamps < bin_end))
            if len(indices[0]) > 0:
                bytes_per_second[i] = np.sum(byte_counts[indices])

        speeds_mbps = (bytes_per_second * 8) / 1_000_000
        peak_speed_mbps = np.max(speeds_mbps) if len(speeds_mbps) > 0 else 0

        # --- Print final results ---
        print("\n" + "="*30)
        print("      Speed Test Results")
        print("="*30)
        print(f"  Average Speed: {avg_speed_mbps:.2f} Mbps")
        print(f"  Peak Speed   : {peak_speed_mbps:.2f} Mbps")
        print("="*30)

        # --- Generate plot ---
        self._plot_results(speeds_mbps)
        
    def _plot_results(self, speeds_mbps):
        """Generates a speed curve plot."""
        try:
            plt.figure(figsize=(10, 5))
            plt.plot(np.arange(len(speeds_mbps)), speeds_mbps, marker='o', linestyle='-')
            
            test_type = "Download" if self.reverse else "Upload"
            plt.title(f'Network Speed Over Time ({test_type})')
            plt.xlabel('Time (seconds)')
            plt.ylabel('Speed (Mbps)')
            plt.grid(True)
            plt.xticks(np.arange(0, len(speeds_mbps), step=max(1, len(speeds_mbps)//10)))

            filename = 'speed_curve.png'
            plt.savefig(filename)
            print(f"[*] Speed curve graph saved to '{filename}'")
        except Exception as e:
            print(f"\n[WARNING] Could not generate plot. Matplotlib error: {e}")
            print("[WARNING] Ensure you are in a graphical environment or have required backends.")


def main_py():
    parser = argparse.ArgumentParser(description="HTTP Speed Test Script")
    subparsers = parser.add_subparsers(dest="mode", required=True)

    # Server parser
    server_parser = subparsers.add_parser("server", help="Run in server mode")
    server_parser.add_argument("--listen", default="0.0.0.0:8080", help="Address and port to listen on")

    # Client parser
    client_parser = subparsers.add_parser("client", help="Run in client mode")
    client_parser.add_argument("--server", required=True, help="Server address and port (e.g., 1.1.1.1:8080)")
    client_parser.add_argument("--time", default="10s", help="Test duration (e.g., 10s, 1m)")
    client_parser.add_argument("--threads", type=int, default=4, help="Number of concurrent threads")
    client_parser.add_argument("--Reverse", action='store_true', help="Run a download test instead of upload")

    args = parser.parse_args()

    if args.mode == "server":
        run_server(args.listen)
    elif args.mode == "client":
        # Parse time string like '10s' or '1m'
        time_str = args.time.lower()
        if time_str.endswith('s'):
            duration = int(time_str[:-1])
        elif time_str.endswith('m'):
            duration = int(time_str[:-1]) * 60
        else:
            duration = int(time_str)
        
        client = Client(args.server, duration, args.threads, args.Reverse)
        client.run_test()

if __name__ == "__main__":
    main_py()
EOF

    # --- Execute Python Script with appropriate arguments ---
    if [ "$MODE" == "server" ]; then
        check_and_install_deps # Dependencies only checked when script is actually run
        print_info "Starting in Server Mode..."
        python3 "$TMP_PY_SCRIPT" server --listen "$LISTEN_ADDR"
    elif [ "$MODE" == "client" ]; then
        if [ -z "$SERVER_ADDR" ]; then
            print_error "Client mode requires a --server parameter."
            exit 1
        fi
        check_and_install_deps
        print_info "Starting in Client Mode..."
        
        # Construct arguments for the python script
        PY_ARGS="client --server $SERVER_ADDR --time $TEST_TIME --threads $THREADS"
        if [ "$REVERSE" = true ]; then
            PY_ARGS="$PY_ARGS --Reverse"
        fi
        
        # Use 'unbuffer' if available to get real-time output, otherwise just run directly
        if command -v unbuffer &> /dev/null; then
            unbuffer python3 "$TMP_PY_SCRIPT" $PY_ARGS
        else
            python3 -u "$TMP_PY_SCRIPT" $PY_ARGS
        fi
    else
        print_error "Invalid mode specified: $MODE. Use 'server' or 'client'."
        exit 1
    fi
}

# Run the main function with all script arguments
main "$@"
