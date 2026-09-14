# TP Haute Disponibilité — VirtualBox

Ce dépôt est aligné avec le TP imposant une architecture **VirtualBox à 5 VM**:

- `LB1` et `LB2` : HAProxy + Keepalived + nftables
- `WEB1` et `WEB2` : nginx + php-fpm + nftables
- `CLIENT` : scripts de validation

## Arborescence

- `configs/` : configurations par VM
- `scripts/` : scripts d'exploitation et de validation
- `mesures/` : mesures brutes (CSV)
- `pv/` : procès-verbaux de tests
- `incidents/` : PV d'incidents (phase 7)
- `exploitation/` : procédures d'exploitation
- `docs/` : architecture, plan d'adressage, sécurité

## Plan d'adressage

- Réseau clients/LB : `192.168.10.0/24`
- Réseau LB/WEB : `192.168.20.0/24`
- Réseau VRRP/cluster : `10.99.99.0/24`

### IP par rôle

- `LB1` : `192.168.10.11`, `192.168.20.11`, `10.99.99.11`
- `LB2` : `192.168.10.12`, `192.168.20.12`, `10.99.99.12`
- `WEB1` : `192.168.20.21`
- `WEB2` : `192.168.20.22`
- `CLIENT` : `192.168.10.31`

### VIP

- VIP client : `192.168.10.100`
- VIP web : `192.168.20.100`

## Vérification rapide

Depuis `CLIENT`:

```bash
bash scripts/check-dispo.sh http://192.168.10.100 60 2
```

Les mesures sont enregistrées dans `mesures/disponibilite.csv` et `mesures/latence.csv`.
