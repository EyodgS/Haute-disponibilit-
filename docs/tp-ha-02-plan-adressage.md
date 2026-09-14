# TP-HA-02 — Plan d’adressage

## Réseaux

### Réseau `192.168.10.0/24` (CLIENT <-> LB)

- LB1: `192.168.10.11`
- LB2: `192.168.10.12`
- CLIENT: `192.168.10.50`
- VIP externe: `192.168.10.100`

### Réseau `192.168.20.0/24` (LB <-> WEB)

- LB1: `192.168.20.11`
- LB2: `192.168.20.12`
- WEB1: `192.168.20.21`
- WEB2: `192.168.20.22`
- VIP interne: `192.168.20.100`

### Réseau `10.99.99.0/24` (cluster VRRP)

- LB1: `10.99.99.11`
- LB2: `10.99.99.12`

## Routes minimales

- CLIENT: accès direct L2 à `192.168.10.100`
- WEB1/WEB2: route retour vers `192.168.10.0/24` via LB actif

## Matrice de flux

| ID | Source | Destination | Port/Proto | Sens | Finalité | Contrôle de sécurité |
|---|---|---|---|---|---|---|
| F1 | CLIENT `192.168.10.50` | VIP externe `192.168.10.100` | TCP/80 | Entrant | Accès portail web | Filtrage nftables LB + HAProxy |
| F2 | LB actif `192.168.20.11/12` | WEB1 `192.168.20.21` | TCP/80 | Sortant LB | Proxy HTTP vers backend | ACL LB + nftables WEB |
| F3 | LB actif `192.168.20.11/12` | WEB2 `192.168.20.22` | TCP/80 | Sortant LB | Proxy HTTP vers backend | ACL LB + nftables WEB |
| F4 | LB1 `10.99.99.11` | LB2 `10.99.99.12` | VRRP (proto 112) | Bidirectionnel | Élection MASTER/BACKUP | Keepalived + filtrage protocolaire |
| F5 | Admin | LB1/LB2/WEB1/WEB2 | TCP/22 | Entrant admin | Administration distante | Restriction SSH + journalisation |
| F6 | LB1/LB2 | VIP `192.168.10.100` et `192.168.20.100` | VRRP/IP | Local hôte | Portage VIP actif/passif | Keepalived priorité/healthchecks |
