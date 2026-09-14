# TP-HA-07 — Analyse des SPOF résiduels

## SPOF identifiés

1. **Alimentation/hôte physique unique** si toutes les VM tournent sur un seul poste.
2. **Stockage local unique** des disques virtuels.
3. **Absence de réplication base de données** si l'application métier persiste sur une DB unique.

## Réductions proposées

- Répartir les VM sur au moins 2 hôtes physiques
- Sauvegardes automatisées hors hôte
- Ajouter réplication base de données en phase suivante
