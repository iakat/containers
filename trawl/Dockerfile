FROM debian:trixie-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wireguard-tools iproute2 iptables \
        rclone rsync lsyncd sshfs fuse3 \
        openssh-client dropbear \
        socat netcat-openbsd curl wget jq \
        inotify-tools tcpdump mtr-tiny dnsutils \
        procps strace tmux file less zstd && \
    rm -rf /var/lib/apt/lists/* && \
    curl -fsSL https://github.com/aptible/supercronic/releases/download/v0.2.33/supercronic-linux-amd64 \
        -o /usr/local/bin/supercronic && \
    chmod +x /usr/local/bin/supercronic && \
    mkdir -p /etc/wireguard /data

VOLUME ["/data", "/etc/wireguard"]
EXPOSE 51820/udp

RUN cat > /entrypoint.sh << 'SCRIPT'
#!/bin/bash
set -e

cleanup() {
    kill $(jobs -p) 2>/dev/null || true
    for conf in /etc/wireguard/wg*.conf; do
        [ -f "$conf" ] && wg-quick down "$(basename "${conf%.conf}")" 2>/dev/null || true
    done
    exit 0
}
trap cleanup SIGTERM SIGINT

# generate default wg0 only if no configs exist
if ! ls /etc/wireguard/wg*.conf 2>/dev/null | grep -q .; then
    [ -f /etc/wireguard/privatekey ] || {
        wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey
        chmod 600 /etc/wireguard/privatekey
        echo "[INFO] pubkey: $(cat /etc/wireguard/publickey)"
    }
    cat > /etc/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = $(cat /etc/wireguard/privatekey)
Address = ${WG_IP:-192.168.192.2}/32
ListenPort = 51820

[Peer]
PublicKey = ${WG_CLIENT_PUBKEY:-CHANGEME}
AllowedIPs = ${WG_CLIENT_IP:-192.168.192.1}/32
EOF
    chmod 600 /etc/wireguard/wg0.conf
fi

# bring up all WG interfaces
for conf in /etc/wireguard/wg*.conf; do
    [ -f "$conf" ] && wg-quick up "$(basename "${conf%.conf}")" && \
        echo "[INFO] up: $(basename "${conf%.conf}")"
done

exec ${CMD:-sleep infinity}
SCRIPT

RUN chmod +x /entrypoint.sh
CMD ["/entrypoint.sh"]
