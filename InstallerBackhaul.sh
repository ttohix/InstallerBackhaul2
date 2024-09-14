#!/bin/bash

show_menu() {
    clear
    echo "----------------------------------"
    echo "Backhaul Installer"
    echo "https://github.com/PixelShellGIT"
    echo "Thanks to Musixal"
    echo "----------------------------------"
    ipv4=$(ip -4 a | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v "127.0.0.1")
    ipv6=$(ip -6 a | grep -oP '(?<=inet6\s)[a-fA-F0-9:]+(?=/)' | grep -v "::1")
    echo "IPv4: $ipv4"
    if [ -z "$ipv6" ]; then
        echo -e "IPv6: \e[31mNot Available\e[0m"
    else
        echo "IPv6: $ipv6"
    fi
    echo "----------------------------------"
    echo "1 - Install core"
    echo "2 - Configure"
    echo "3 - Uninstall core"
    echo "4 - Update core"
    echo "5 - Restart core"
    echo "6 - Status"
    echo "0 - Exit"
}

install_core() {
    clear
    echo "Installing core..."
    arch=$(uname -m)
    mkdir -p backhaul
    cd backhaul
    if [ "$arch" == "x86_64" ]; then
        wget https://github.com/Musixal/Backhaul/releases/download/v0.2.1/backhaul_linux_amd64.tar.gz
        tar -xf backhaul_linux_amd64.tar.gz
        rm backhaul_linux_amd64.tar.gz
    elif [ "$arch" == "aarch64" ]; then
        wget https://github.com/Musixal/Backhaul/releases/download/v0.2.1/backhaul_darwin_arm64.tar.gz
        tar -xf backhaul_darwin_arm64.tar.gz
        rm backhaul_darwin_arm64.tar.gz
    else
        echo "Unsupported architecture: $arch"
        sleep 2
        return
    fi
    chmod +x backhaul
    mv backhaul /usr/bin/backhaul
    echo "Backhaul installed successfully!"
    sleep 2
    cd ..
}

uninstall_core() {
    echo "Uninstalling core..."
    rm -f /usr/bin/backhaul
    echo "Backhaul uninstalled successfully!"
    sleep 2
}

update_core() {
    echo "Updating core..."
    rm -f /usr/bin/backhaul
    install_core
    sudo systemctl restart backhaul.service
    echo "Backhaul updated successfully!"
    sleep 2
}

restart_core() {
    echo "Restarting core..."
    sudo systemctl restart backhaul.service
    echo "Backhaul restarted successfully!"
    sleep 2
}

status_core() {
    sudo systemctl status backhaul.service
    echo -e "\nPress Enter to return to menu..."
    read -r
}

configure_iran() {
    clear
    echo "Configuring Iran Server..."

    read -p "Enter tunnel port: " tunnel_port
    read -p "Enter security token: " token
    read -p "Do you want nodelay enabled? (true/false): " nodelay
    read -p "How many ports do you have?: " port_count

    ports=()
    for (( i=1; i<=port_count; i++ )); do
        read -p "Enter input port $i: " input_port
        read -p "Enter output port $i: " output_port
        ports+=("\"$input_port=$output_port\"")
    done

    read -p "Enter web port: " web_port

    read -p "Channel size (default 2048): " channel_size
    channel_size=${channel_size:-2048}
    read -p "Connection pool (default 8): " connection_pool
    connection_pool=${connection_pool:-8}
    read -p "Heartbeat (default 20): " heartbeat
    heartbeat=${heartbeat:-20}

    echo "1 - tcp"
    echo "2 - tcpmux"
    echo "3 - ws"
    echo "4 - wss"
    read -p "Choose protocol: " protocol_choice
    case $protocol_choice in
        1) protocol="tcp" ;;
        2) protocol="tcpmux" ;;
        3) protocol="ws" ;;
        4) 
            protocol="wss"
            read -p "Enter TLS cert (default /root/server.crt): " tls_cert
            tls_cert=${tls_cert:-/root/server.crt}
            read -p "Enter TLS key (default /root/server.key): " tls_key
            tls_key=${tls_key:-/root/server.key}
            ;;
    esac

    echo "[server]" > /root/backhaul/config.toml
    echo "bind_addr = \"0.0.0.0:$tunnel_port\"" >> /root/backhaul/config.toml
    echo "transport = \"$protocol\"" >> /root/backhaul/config.toml
    echo "token = \"$token\"" >> /root/backhaul/config.toml
    echo "keepalive_period = 20" >> /root/backhaul/config.toml
    echo "nodelay = $nodelay" >> /root/backhaul/config.toml
    echo "channel_size = $channel_size" >> /root/backhaul/config.toml
    echo "connection_pool = $connection_pool" >> /root/backhaul/config.toml
    echo "heartbeat = $heartbeat" >> /root/backhaul/config.toml
    echo "mux_session = 1" >> /root/backhaul/config.toml
    echo "mux_version = 1" >> /root/backhaul/config.toml
    echo "mux_framesize = 32768" >> /root/backhaul/config.toml
    echo "mux_recievebuffer = 4194304" >> /root/backhaul/config.toml
    echo "mux_streambuffer = 65536" >> /root/backhaul/config.toml
    echo "sniffer = false" >> /root/backhaul/config.toml
    echo "web_port = $web_port" >> /root/backhaul/config.toml
    echo "sniffer_log = \"backhaul.json\"" >> /root/backhaul/config.toml
    if [ "$protocol" == "wss" ]; then
        echo "tls_cert = \"$tls_cert\"" >> /root/backhaul/config.toml
        echo "tls_key = \"$tls_key\"" >> /root/backhaul/config.toml
    fi
    echo "ports = [" >> /root/backhaul/config.toml
    for port in "${ports[@]}"; do
        echo "    $port," >> /root/backhaul/config.toml
    done
    echo "]" >> /root/backhaul/config.toml

    create_service_file
    echo "Iran Server configuration created successfully!"
    sleep 2
}

configure_kharej() {
    clear
    echo "Configuring Kharej Server..."

    read -p "Enter remote IP address: " remote_ip
    read -p "Enter tunnel port: " tunnel_port
    read -p "Enter security token: " token
    read -p "Do you want nodelay enabled? (true/false): " nodelay
    read -p "Enter web port: " web_port

    echo "1 - tcp"
    echo "2 - tcpmux"
    echo "3 - ws"
    echo "4 - wss"
    read -p "Choose protocol: " protocol_choice
    case $protocol_choice in
        1) protocol="tcp" ;;
        2) protocol="tcpmux" ;;
        3) protocol="ws" ;;
        4) 
            protocol="wss"
            read -p "Enter TLS cert (default /root/server.crt): " tls_cert
            tls_cert=${tls_cert:-/root/server.crt}
            read -p "Enter TLS key (default /root/server.key): " tls_key
            tls_key=${tls_key:-/root/server.key}
            ;;
    esac

    echo "[client]" > /root/backhaul/config.toml
    echo "remote_addr = \"$remote_ip:$tunnel_port\"" >> /root/backhaul/config.toml
    echo "transport = \"$protocol\"" >> /root/backhaul/config.toml
    echo "token = \"$token\"" >> /root/backhaul/config.toml
    echo "keepalive_period = 20" >> /root/backhaul/config.toml
    echo "nodelay = $nodelay" >> /root/backhaul/config.toml
    echo "retry_interval = 1" >> /root/backhaul/config.toml
    echo "log_level = \"info\"" >> /root/backhaul/config.toml
    echo "mux_session = 1" >> /root/backhaul/config.toml
    echo "mux_version = 1" >> /root/backhaul/config.toml
    echo "mux_framesize = 32768" >> /root/backhaul/config.toml
    echo "mux_recievebuffer = 4194304" >> /root/backhaul/config.toml
    echo "mux_streambuffer = 65536" >> /root/backhaul/config.toml
    echo "sniffer = false" >> /root/backhaul/config.tom
        echo "web_port = $web_port" >> /root/backhaul/config.toml
    echo "sniffer_log = \"backhaul.json\"" >> /root/backhaul/config.toml
    if [ "$protocol" == "wss" ]; then
        echo "tls_cert = \"$tls_cert\"" >> /root/backhaul/config.toml
        echo "tls_key = \"$tls_key\"" >> /root/backhaul/config.toml
    fi

    create_service_file
    echo "Kharej Server configuration created successfully!"
    sleep 2
}

create_service_file() {
    echo "Creating systemd service file..."
    echo "[Unit]" > /etc/systemd/system/backhaul.service
    echo "Description=Backhaul Service" >> /etc/systemd/system/backhaul.service
    echo "After=network.target" >> /etc/systemd/system/backhaul.service
    echo "" >> /etc/systemd/system/backhaul.service
    echo "[Service]" >> /etc/systemd/system/backhaul.service
    echo "ExecStart=/usr/bin/backhaul -c /root/backhaul/config.toml" >> /etc/systemd/system/backhaul.service
    echo "Restart=always" >> /etc/systemd/system/backhaul.service
    echo "RestartSec=3" >> /etc/systemd/system/backhaul.service
    echo "User=root" >> /etc/systemd/system/backhaul.service
    echo "LimitNOFILE=4096" >> /etc/systemd/system/backhaul.service
    echo "" >> /etc/systemd/system/backhaul.service
    echo "[Install]" >> /etc/systemd/system/backhaul.service
    echo "WantedBy=multi-user.target" >> /etc/systemd/system/backhaul.service

    sudo systemctl daemon-reload
    sudo systemctl enable backhaul.service
    sudo systemctl start backhaul.service
    echo "Service created and started successfully!"
}

while true; do
    show_menu
    read -p "Choose an option: " choice
    case $choice in
        1) install_core ;;
        2) 
            echo "1 - Iran Server"
            echo "2 - Kharej Server"
            read -p "Choose server type: " server_choice
            case $server_choice in
                1) configure_iran ;;
                2) configure_kharej ;;
            esac
            ;;
        3) uninstall_core ;;
        4) update_core ;;
        5) restart_core ;;
        6) status_core ;;
        0) exit 0 ;;
        *) echo "Invalid option. Please choose a valid option." ;;
    esac
done
