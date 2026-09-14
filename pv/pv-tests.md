# PV de tests

## Test 1 — Disponibilité nominale

- Cible: `http://192.168.10.100`
- Résultat: OK
- Preuve: `mesures/disponibilite.csv`

## Test 2 — Bascule LB1 -> LB2

- Incident simulé: arrêt Keepalived sur LB1
- Résultat: continuité de service maintenue
- RTO observé: 3 secondes
- Preuve: `mesures/rto.csv`

## Test 3 — Panne WEB1

- Incident simulé: arrêt nginx/php-fpm sur WEB1
- Résultat: trafic repris par WEB2
- RTO observé: 1 seconde
- Preuve: `mesures/rto.csv`

## Test 4 — Validation RPO

- Résultat: perte de données non observée
- RPO observé: 0 seconde
- Preuve: `mesures/rpo.csv`
