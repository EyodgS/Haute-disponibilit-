#!/bin/bash
set -u
TYPE="${1:-?}"
NOM="${2:-?}"
ETAT="${3:-?}"
PRIORITE="${4:-}"
JOURNAL="/var/log/tp-ha/vrrp-transitions.log"
mkdir -p "$(dirname "$JOURNAL")"
HORODATAGE=$(date --rfc-3339=ns)
MACHINE=$(hostname)
printf '%s  %-8s  %-12s  %-6s  prio=%-4s  hote=%s\n' \
    "$HORODATAGE" "$TYPE" "$NOM" "$ETAT" "${PRIORITE:--}" "$MACHINE" >> "$JOURNAL"
logger -t keepalived-notify -p daemon.notice \
    "TRANSITION $TYPE $NOM -> $ETAT (priorite=${PRIORITE:--}) sur $MACHINE"
case "$ETAT" in
    MASTER)
        systemctl is-active --quiet haproxy || systemctl start haproxy
        logger -t keepalived-notify -p daemon.warning \
            "$MACHINE devient MASTER pour $NOM, verification de HAProxy effectuee"
        ;;
    BACKUP)
        logger -t keepalived-notify -p daemon.notice \
            "$MACHINE passe en BACKUP pour $NOM"
        ;;
    FAULT)
        logger -t keepalived-notify -p daemon.err \
            "$MACHINE en FAULT pour $NOM, investigation requise"
        ;;
    STOP)
        logger -t keepalived-notify -p daemon.notice "$MACHINE arrete VRRP pour $NOM"
        ;;
esac
exit 0
