# Plan d'adressage

## Réseau 192.168.10.0/24 (CLIENT <-> LB)

- LB1: `192.168.10.11`
- LB2: `192.168.10.12`
- CLIENT: `192.168.10.31`
- VIP externe: `192.168.10.100`

## Réseau 192.168.20.0/24 (LB <-> WEB)

- LB1: `192.168.20.11`
- LB2: `192.168.20.12`
- WEB1: `192.168.20.21`
- WEB2: `192.168.20.22`
- VIP interne: `192.168.20.100`

## Réseau 10.99.99.0/24 (cluster/VRRP)

- LB1: `10.99.99.11`
- LB2: `10.99.99.12`

## Routes minimales

- CLIENT: route vers `192.168.10.100` via L2 locale
- WEB1/WEB2: route retour vers `192.168.10.0/24` via LB actifs
