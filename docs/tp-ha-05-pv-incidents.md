# TP-HA-05 — PV incidents (phase 7)

## Incident A — Perte LB actif

- Détection: timeout sonde CLIENT
- Action: bascule VRRP automatique
- Impact: interruption courte
- RTO: 3s
- Correctif: vérification périodique des priorités VRRP

## Incident B — Perte WEB1

- Détection: healthcheck HAProxy en échec
- Action: retrait automatique de WEB1 du pool
- Impact: dégradation sans interruption totale
- RTO: 1s
- Correctif: procédure de redémarrage service web

## Incident C — Erreur de règle nftables WEB2

- Détection: échec healthcheck WEB2
- Action: rollback de configuration nftables
- Impact: service maintenu via WEB1
- Correctif: revue croisée des règles avant application
