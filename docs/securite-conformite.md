# Sécurité et conformité

## Contrôles techniques appliqués

- Politique **deny by default** avec nftables
- Exposition minimale des ports:
  - LB: 22/tcp, 80/tcp, 443/tcp, VRRP (proto 112)
  - WEB: 22/tcp, 80/tcp
- Accès SSH restreint au réseau d'administration
- Journalisation de base activée côté services et système

## Conformité TP

- Continuité de service validée par tests de bascule
- Mesure RTO/RPO documentée dans `mesures/` et `pv/`
- Procédure d'incident formalisée dans `incidents/`
