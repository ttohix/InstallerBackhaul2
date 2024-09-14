#!/bin/bash

show_menu() {
    clear
    echo "----------------------------------"
    echo "installer backhaul"
    echo "https://gitHub.com/PixelShellGIT"
    echo "Thanks to musixal"
    echo "----------------------------------"
    ipv4=$(ip -4 a | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v "127.0.0.1")
    ipv6=$(ip -6 a | grep -oP '(?<=inet6\s)[a-fA-F0-9:]+(?=/)' | grep -v "::1")
    echo "IPv4: $ipv4"
    if [ -z "$ipv6" ]; then
        echo -e "IPv6: \e[31mندارد\e[0m"
    else
        echo "IPv6: $ipv6"
    fi
    echo "----------------------------------"
    echo "1 - Install core"
    echo "2 - Configure"
    echo "3 - Uninstall core"
    echo "4 - Update"
    echo "5 - Restart"
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

    echo "1 - IPv4"
    echo "2 - IPv6"
    read -p "Choose IP version: " ip_version

    read -p "Enter tunnel port: " tunnel_port
    read -p "Enter security token: " token
    read -p "Do you want nodelay enabled? (true/false): " nodelay
    read -p "How many ports do you have?: " port_count

    ports=()
    for (( i=1; i<=port_count; i++ ))
    do
        read -p "Enter input port $i: " input_port
        read -p "Enter output port $i: " output_port
        ports+=("\"$input_port=$output_port\"")
    done

    read -p "Enter web port: " web_port

    if [ "$ip_version" == "1" ]; then
        bind_addr="0.0.0.0"
    else
        bind_addr="::"
    fi

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
            read -p "Enter tls_cert (default: /root/server.crt): " tls_cert
            read -p "Enter tls_key (default: /root/server.key): " tls_key
            tls_cert=${tls_cert:-/root/server.crt}
            tls_key=${tls_key:-/root/server.key}
            ;;
    esac

    echo "[server]" > /root/backhaul/config.toml
    echo "bind_addr = \"$bind_addr:$tunnel_port\"" >> /root/backhaul/config.toml
    echo "transport = \"$protocol\"" >> /root/backhaul/config.toml
    echo "token = \"$token\"" >> /root/backhaul/config.toml
    echo "keepalive_period = 20" >> /root/backhaul/config.toml
    echo "nodelay = $nodelay" >> /root/backhaul/config.toml
    echo "channel_size = 2048" >> /root/backhaul/config.toml
    echo "connection_pool = 8" >> /root/backhaul/config.toml
    echo "mux_session = 1" >> /root/backhaul/config.toml
    echo "ports = [" >> /root/backhaul/config.toml
    for port in "${ports[@]}"
    do
        echo "    $port," >> /root/backhaul/config.toml
    done
    echo "]" >> /root/backhaul/config.toml
    echo "sniffer = true" >> /root/backhaul/config.toml
    echo "web_port = $web_port" >> /root/backhaul/config.toml
    echo "sniffer_log = \"backhaul.json\"" >> /root/backhaul/config.toml

    if [ "$protocol_choice" == "4" ]; then
        echo "tls_cert = \"$tls_cert\"" >> /root/backhaul/config.toml
        echo "tls_key = \"$tls_key\"" >> /root/backhaul/config.toml
    fi

    echo "[Unit]" > /etc/systemd/system/backhaul.service
    echo "Description=Backhaul Reverse Tunnel Service" >> /etc/systemd/system/backhaul.service
    echo "After=network.target" >> /etc/systemd/system/backhaul.service
    echo "[Service]" >> /etc/systemd/system/backhaul.service
    echo "Type=simple" >> /etc/systemd/system/backhaul.service
    echo "ExecStart=/usr/bin/backhaul -c /root/backhaul/config.toml" >> /etc/systemd/system/backhaul.service
    echo "Restart=always" >> /etc/systemd/system/backhaul.service
    echo "RestartSec=3" >> /etc/systemd/system/backhaul.service
    echo "LimitNOFILE=1048576" >> /etc/systemd/system/backhaul.service
    echo "[Install]" >> /etc/systemd/system/backhaul.service
    echo "WantedBy=multi-user.target" >> /etc/systemd/system/backhaul.service

    sudo systemctl daemon-reload
    sudo systemctl enable backhaul.service
    sudo systemctl start backhaul.service

    echo "Backhaul config for Iran created successfully!"
    sleep 2
}

configure_kharej() {
    clear
    echo "Configuring Kharej Server..."

    echo "1 - IPv4"
    echo "2 - IPv6"
    read -p "Choose IP version: " ip_version

    if [ "$ip_version" == "1" ]; then
        read -p "Enter remote IPv4 address: " remote_ip
    else
        read -p "Enter remote IPv6 address: " remote_ip
        remote_ip="[$remote_ip]"
    fi

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
            read -p "Enter tls_cert (default: /root/server.crt): " tls_cert
            read -p "Enter tls_key (default: /root/server.key): " tls_key
            tls_cert=${tls_cert:-/root/server.crt}
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
    echo "sniffer = false" >> /root/backhaul/config.toml
    echo "web_port = $web_port" >> /root/backhaul/config.toml
    echo "sniffer_log = \"backhaul.json\"" >> /root/backhaul/config.toml

    if [ "$protocol_choice" == "4" ]; then
        echo "tls_cert = \"$tls_cert\"" >> /root/backhaul/config.toml
        echo "tls_key = \"$tls_key\"" >> /root/backhaul/config.toml
    fi

    echo "[Unit]" > /etc/systemd/system/backhaul.service
    echo "Description=Backhaul Reverse Tunnel Service" >> /etc/systemd/system/backhaul.service
    echo "After=network.target" >> /etc/systemd/system/backhaul.service
    echo "[Service]" >> /etc/systemd/system/backhaul.service
    echo "Type=simple" >> /etc/systemd/system/backhaul.service
    echo "ExecStart=/usr/bin/backhaul -c /root/backhaul/config.toml" >> /etc/systemd/system/backhaul.service
    echo "Restart=always" >> /etc/systemd/system/backhaul.service
    echo "RestartSec=3" >> /etc/systemd/system/backhaul.service
    echo "LimitNOFILE=1048576" >> /etc/systemd/system/backhaul.service
    echo "[Install]" >> /etc/systemd/system/backhaul.service
    echo "WantedBy=multi-user.target" >> /etc/systemd/system/backhaul.service

    sudo systemctl daemon-reload
    sudo systemctl enable backhaul.service
    sudo systemctl start backhaul.service

    echo "Backhaul config for Kharej created successfully!"
    sleep 2
}

while true; do
    show_menu
    read -p "Enter your choice: " choice
    case $choice in
        1) install_core ;;
        2) 
            echo "1 - Iran Server"
            echo "2 - Kharej Server"
            read -p "Choose server to configure: " server_choice
            case $server_choice in
                1) configure_iran ;;
                2) configure_kharej ;;
                *) echo "Invalid option!" ;;
            esac
            ;;
        3) uninstall_core ;;
        4) update_core ;;
        5) restart_core ;;
        6) status_core ;;
        0) exit ;;
        *) echo "Invalid option!" ;;
    esac
done