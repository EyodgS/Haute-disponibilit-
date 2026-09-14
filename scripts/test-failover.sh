#!/usr/bin/env bash
set -euo pipefail

VIP_URL="${1:-http://192.168.10.100/health}"
OUT_RTO="mesures/rto.csv"

mkdir -p mesures

echo "event,start_ts,end_ts,rto_seconds" > "$OUT_RTO"

start_ts="$(date -Iseconds)"
start_epoch="$(date +%s)"

echo "Déclenche une panne contrôlée sur le LB actif puis appuie sur Entrée une fois fait."
read -r _

while true; do
  if curl -fsS "$VIP_URL" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

end_ts="$(date -Iseconds)"
end_epoch="$(date +%s)"
rto="$(( end_epoch - start_epoch ))"

echo "failover_lb,$start_ts,$end_ts,$rto" >> "$OUT_RTO"
echo "RTO mesuré: ${rto}s (fichier: $OUT_RTO)"
