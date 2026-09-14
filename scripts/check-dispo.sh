#!/usr/bin/env bash
set -euo pipefail

TARGET_URL="${1:-http://192.168.10.100}"
DURATION_SECONDS="${2:-60}"
INTERVAL_SECONDS="${3:-2}"

OUT_DISPO="mesures/disponibilite.csv"
OUT_LATENCE="mesures/latence.csv"

mkdir -p mesures

echo "timestamp,reachable,http_code" > "$OUT_DISPO"
echo "timestamp,latency_seconds" > "$OUT_LATENCE"

end_time=$(( $(date +%s) + DURATION_SECONDS ))

while [ "$(date +%s)" -lt "$end_time" ]; do
  ts="$(date -Iseconds)"

  response="$(curl -s -o /tmp/tp_ha_resp.txt -w '%{http_code} %{time_total}' "$TARGET_URL" || true)"
  code="$(echo "$response" | awk '{print $1}')"
  latency="$(echo "$response" | awk '{print $2}')"

  if [ -n "$code" ] && [ "$code" -ge 200 ] && [ "$code" -lt 500 ]; then
    reachable=1
  else
    reachable=0
    code="000"
    latency="0"
  fi

  echo "$ts,$reachable,$code" >> "$OUT_DISPO"
  echo "$ts,$latency" >> "$OUT_LATENCE"

  sleep "$INTERVAL_SECONDS"
done

echo "Mesures écrites dans $OUT_DISPO et $OUT_LATENCE"
