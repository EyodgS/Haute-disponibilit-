#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-http://localhost:8080}"

echo "[1/4] Vérification endpoint principal..."
curl -fsS "$BASE_URL/" >/dev/null

echo "[2/4] Vérification endpoint health..."
curl -fsS "$BASE_URL/health" >/dev/null

echo "[3/4] Vérification endpoint appointments..."
curl -fsS "$BASE_URL/appointments" >/dev/null

echo "[4/4] Test de continuité après arrêt d'une instance..."
docker compose stop app1 >/dev/null
sleep 3
curl -fsS "$BASE_URL/" >/dev/null

echo "Restauration du service app1..."
docker compose start app1 >/dev/null

echo "OK - tests de fumée passés."
