# TP-HA-08 — Sécurité et conformité

## Contrôles techniques appliqués

- Politique **deny by default** avec nftables
- Exposition minimale des ports:
  - LB: 22/tcp, 80/tcp, 443/tcp, VRRP (proto 112)
  - WEB: 22/tcp, 80/tcp
- Accès SSH restreint au réseau d'administration
- Journalisation de base activée côté services et système

## Alignement NIS2 / RGPD (niveau TP)

- Continuité de service validée par tests de bascule
- Mesure RTO/RPO documentée dans `mesures/`
- Procédure d'incident formalisée dans `docs/tp-ha-05-pv-incidents.md`
- Procédures d’exploitation documentées dans `docs/tp-ha-06-exploitation.md`
