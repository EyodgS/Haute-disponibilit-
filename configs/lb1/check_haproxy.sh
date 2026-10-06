# Watchdog : si HAProxy est inactif depuis 2 cycles, force la bascule
if ! systemctl is-active --quiet haproxy; then
    # Attendre confirmation
    sleep 2
    if ! systemctl is-active --quiet haproxy; then
        echo "$(date +%T) - HAProxy DOWN, forcing VRRP failover" >> /var/log/check_haproxy.log
        # Abaisser la priorité via une commande keepalived
        systemctl stop keepalived
        exit 1
    fi
fi
echo "$(date +%T) - HAProxy OK" >> /var/log/check_haproxy.log
exit 0
