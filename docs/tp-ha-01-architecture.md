# TP-HA-01 — Architecture cible

## Objectif

Fournir une plateforme web tolérante aux pannes avec bascule automatique des load balancers.

## Topologie

- 2 load balancers (`LB1`, `LB2`) en redondance VRRP (Keepalived)
- 2 serveurs web (`WEB1`, `WEB2`) derrière HAProxy
- 1 poste `CLIENT` (`192.168.10.50`) pour les vérifications

Flux principal:

`CLIENT -> VIP 192.168.10.100 -> HAProxy (LB actif) -> WEB1/WEB2`

## Technologies

- **HAProxy** : répartition de charge HTTP
- **Keepalived (VRRP)** : bascule LB1/LB2 avec VIP
- **nginx + php-fpm** : service web sur WEB1/WEB2
- **nftables** : filtrage réseau sur chaque VM
