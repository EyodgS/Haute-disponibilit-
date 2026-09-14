# Architecture Haute Disponibilité — NovaSanté

## 1. Vue d’ensemble

Objectif : assurer la continuité de service du portail de rendez-vous médicaux.

Architecture implémentée :

- Point d’entrée unique : Nginx
- Deux nœuds applicatifs actifs simultanément
- Base PostgreSQL centralisée
- Redis pour externaliser l’état applicatif

## 2. Composants et rôles

- **Nginx** : équilibrage, détection indirecte des pannes applicatives, bascule transparente
- **App1/App2** : service métier redondé
- **PostgreSQL** : persistance des rendez-vous
- **Redis** : base d’extension pour sessions/caches partagés

## 3. Mécanismes HA présents

- Multiplication des instances applicatives
- Politique de redémarrage automatique des conteneurs
- Healthchecks sur chaque composant clé
- Distribution de charge `least_conn`
- Retry upstream côté proxy

## 4. Limites et trajectoire cible

Limite actuelle : base de données en nœud unique.

Trajectoire cible recommandée :

- PostgreSQL HA (Patroni + etcd/Consul + réplication)
- Virtual IP (Keepalived) pour supprimer le SPOF du point d’entrée
- TLS mutuel inter-services pour durcir les flux est-ouest
- Multi-zone / multi-hôte pour résilience infra
