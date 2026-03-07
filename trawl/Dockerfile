FROM alpine:3.23

RUN apk add --no-cache \
    tini bash \
    wireguard-tools iproute2 iptables \
    rclone rsync lsyncd sshfs fuse3 \
    openssh-client-default dropbear \
    socat netcat-openbsd curl wget jq \
    inotify-tools tcpdump mtr bind-tools \
    procps strace tmux file less zstd stunnel && \
    mkdir -p /etc/wireguard /data

VOLUME ["/data", "/etc/wireguard"]
EXPOSE 51820/udp

HEALTHCHECK --interval=30s --timeout=5s \
    CMD wg show | grep -q "latest handshake" || exit 1

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

if ! ls /etc/wireguard/wg*.conf 2>/dev/null | grep -q .; then
    [ -f /etc/wireguard/privatekey ] || {
        wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey
        chmod 600 /etc/wireguard/privatekey
        echo "[INFO] pubkey: $(cat /etc/wireguard/publickey)"
    }
    cat > /etc/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = $(cat /etc/wireguard/privatekey)
Address = ${WG_IP:-100.87.143.201}/32
ListenPort = 51820

[Peer]
PublicKey = ${WG_CLIENT_PUBKEY:-CHANGEME}
AllowedIPs = ${WG_CLIENT_IP:-100.87.143.1}/32
EOF
    chmod 600 /etc/wireguard/wg0.conf
fi

for conf in /etc/wireguard/wg*.conf; do
    [ -f "$conf" ] && wg-quick up "$(basename "${conf%.conf}")" && \
        echo "[INFO] up: $(basename "${conf%.conf}")"
done

exec ${CMD:-sleep infinity}
SCRIPT

RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/entrypoint.sh"]
