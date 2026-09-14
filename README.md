# TP Haute Disponibilité — NovaSanté

## Contexte

Ce dépôt contient le TP de B1 **Administrer et sécuriser les infrastructures**.
Le scénario métier cible la société fictive **NovaSanté** (prise de rendez-vous médicaux) avec des exigences de continuité de service, de sécurité, de conformité **NIS2** et **RGPD**.

## Objectifs du TP

- Garantir la disponibilité d’un service web malgré la panne d’un nœud critique.
- Mettre en place une architecture redondée avec bascule automatique.
- Produire des preuves mesurables: disponibilité, latence, RTO, RPO.
- Documenter exploitation, incidents et conformité.

## Architecture cible (VirtualBox, 5 VM)

- `LB1` et `LB2` : **HAProxy + Keepalived + nftables**
- `WEB1` et `WEB2` : **nginx + php-fpm + nftables**
- `CLIENT` : poste de tests et mesures

### Plan d’adressage synthétique

- Réseau client/LB : `192.168.10.0/24`
- Réseau LB/WEB : `192.168.20.0/24`
- Réseau cluster VRRP : `10.99.99.0/24`

| Rôle | IP |
|---|---|
| LB1 | `192.168.10.11` / `192.168.20.11` / `10.99.99.11` |
| LB2 | `192.168.10.12` / `192.168.20.12` / `10.99.99.12` |
| WEB1 | `192.168.20.21` |
| WEB2 | `192.168.20.22` |
| CLIENT | `192.168.10.50` |
| VIP externe | `192.168.10.100` |
| VIP interne | `192.168.20.100` |

### Schéma logique

`CLIENT (192.168.10.50) -> VIP 192.168.10.100 -> LB actif (HAProxy) -> WEB1 / WEB2`

## Arborescence attendue

- `configs/` : configurations par VM
- `scripts/` : scripts de test et exploitation
- `mesures/` : mesures brutes CSV
- `docs/` : documentation complète normalisée (`tp-ha-*`)

## Documents normalisés

- `docs/tp-ha-01-architecture.md`
- `docs/tp-ha-02-plan-adressage.md`
- `docs/tp-ha-03-plan-de-tests.md`
- `docs/tp-ha-04-pv-tests.md`
- `docs/tp-ha-05-pv-incidents.md`
- `docs/tp-ha-06-exploitation.md`
- `docs/tp-ha-07-spof-residuels.md`
- `docs/tp-ha-08-securite-conformite.md`

## Vérification rapide

Depuis la VM `CLIENT`:

```bash
bash scripts/check-dispo.sh http://192.168.10.100 60 2
```

## Auto-évaluation (documentation)

| Critère | État |
|---|---|
| Contexte métier et réglementaire explicités | ✅ |
| Objectifs techniques explicites | ✅ |
| Schéma/chaîne de flux présent | ✅ |
| Plan d’adressage complet + matrice de flux | ✅ |
| Plan de tests, PV tests et PV incidents fournis | ✅ |
| Procédures d’exploitation + SPOF résiduels | ✅ |
| Mesures disponibilité/latence/RTO/RPO fournies | ✅ |
| Nomenclature documentaire unifiée | ✅ |
