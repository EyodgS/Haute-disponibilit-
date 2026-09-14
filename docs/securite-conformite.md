# Sécurité, NIS2 et RGPD — NovaSanté

## 1. Contexte réglementaire

- **NIS2** : exigences de gestion des risques cyber, continuité et notification d’incident
- **RGPD** : protection des données personnelles de santé (catégorie sensible)

## 2. Mesures techniques prioritaires

1. Gestion des accès
   - Comptes nominatifs
   - Moindre privilège
   - MFA pour les accès d’administration

2. Protection des données
   - Chiffrement TLS (en transit)
   - Chiffrement des sauvegardes et volumes sensibles (au repos)
   - Politique de rétention et purge maîtrisée

3. Journalisation et traçabilité
   - Logs horodatés, centralisés et protégés
   - Corrélation des événements de sécurité
   - Conservation adaptée aux obligations légales

4. Continuité d’activité
   - Supervision active
   - Procédures de bascule
   - PRA/PCA testés régulièrement

## 3. Mesures organisationnelles

- Registre des traitements
- Analyse d’impact (AIPD/DPIA) sur le traitement des données de santé
- Procédure de gestion d’incident et notification
- Sensibilisation sécurité des administrateurs

## 4. Contrôles à produire pour le TP

- Preuve de redondance applicative
- Preuve de test de bascule
- Preuve de sauvegarde/restauration
- Inventaire des risques et mesures de réduction
