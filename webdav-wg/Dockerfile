FROM debian:trixie-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wireguard-tools \
        rclone \
        lsyncd \
        rsync \
        openssh-client \
        inotify-tools \
        iproute2 && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /etc/wireguard /data

VOLUME ["/data", "/etc/wireguard"]
EXPOSE 51820/udp

RUN cat > /entrypoint.sh << 'EOF'
#!/bin/bash
set -e
WG_IFACE="wg0"
cleanup() {
    echo "[INFO] Shutting down..."
    kill $(jobs -p) 2>/dev/null || true
    wg-quick down "${WG_IFACE}" 2>/dev/null || true
    exit 0
}
trap cleanup SIGTERM SIGINT

if [ ! -f /etc/wireguard/privatekey ]; then
    wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey
    chmod 600 /etc/wireguard/privatekey
    wg genpsk > /etc/wireguard/psk
    chmod 600 /etc/wireguard/psk
    echo "[INFO] Generated WireGuard keys. Public key: $(cat /etc/wireguard/publickey)"
fi

if [ ! -f /etc/wireguard/webdav-password ]; then
    tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32 > /etc/wireguard/webdav-password
    chmod 600 /etc/wireguard/webdav-password
    echo "[INFO] Generated WebDAV password: $(cat /etc/wireguard/webdav-password)"
fi

WG_CLIENT_PUBKEY="${WG_CLIENT_PUBKEY:-CHANGEME}"
WG_IP="${WG_IP:-100.87.143.201}"
WG_CLIENT_IP="${WG_CLIENT_IP:-100.87.143.1}"

cat > "/etc/wireguard/${WG_IFACE}.conf" << WGEOF
[Interface]
PrivateKey = $(cat /etc/wireguard/privatekey)
Address = ${WG_IP}/32
ListenPort = 51820

[Peer]
PublicKey = ${WG_CLIENT_PUBKEY}
PresharedKey = $(cat /etc/wireguard/psk)
AllowedIPs = ${WG_CLIENT_IP}/32
WGEOF
chmod 600 "/etc/wireguard/${WG_IFACE}.conf"
wg-quick up "${WG_IFACE}"
echo "[INFO] WireGuard up: ${WG_IP}"

WEBDAV_PASSWORD=$(cat /etc/wireguard/webdav-password)
echo "[INFO] WebDAV credentials: root / ${WEBDAV_PASSWORD}"

DEFAULT_CMD="rclone serve webdav /data --addr ${WG_IP}:8080 --user root --pass ${WEBDAV_PASSWORD} --read-only ${RCLONE_ARGS}"
exec ${CMD_OVERRIDE:-$DEFAULT_CMD}
EOF

RUN chmod +x /entrypoint.sh
CMD ["/entrypoint.sh"]
