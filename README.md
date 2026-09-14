# TP Haute Disponibilité — NovaSanté

Projet complet de TP (16h) pour concevoir, déployer et documenter une plateforme web de prise de rendez-vous médicaux avec des exigences de **haute disponibilité**, de **sécurité**, et de **conformité NIS2/RGPD**.

## 1) Objectifs

- Mettre en place une architecture web tolérante aux pannes
- Garantir la continuité de service applicative (reverse proxy + plusieurs nœuds applicatifs)
- Centraliser la donnée dans une base PostgreSQL
- Proposer un cadre d’exploitation (supervision, sauvegarde, PRA/PCA)
- Documenter les mesures de sécurité et de conformité

## 2) Architecture livrée

Cette version implémente une HA **active/active** sur la couche web/applicative :

- **Nginx** : point d’entrée et équilibrage de charge
- **2 instances applicatives Flask** : `app1`, `app2`
- **PostgreSQL** : stockage métier
- **Redis** : cache/sessions (prévu pour extension)

Schéma logique :

Client → Nginx (LB) → App1/App2 → PostgreSQL

## 3) Arborescence

- `docker-compose.yml` : orchestration de la plateforme
- `app/` : application web de démonstration
- `infra/nginx/nginx.conf` : configuration load balancing + health
- `infra/db/init.sql` : création de schéma et données de base
- `docs/architecture.md` : architecture et choix techniques
- `docs/securite-conformite.md` : NIS2/RGPD et mesures associées
- `docs/exploitation.md` : exploitation, sauvegarde, PRA/PCA
- `docs/plan-de-tests.md` : plan de tests HA
- `scripts/smoke_test.sh` : test de disponibilité et bascule

## 4) Prérequis

- Docker + Docker Compose
- Port TCP `8080` libre

## 5) Démarrage rapide

```bash
docker compose up -d --build
```

Accès application :

- [http://localhost:8080](http://localhost:8080)
- Health check applicatif : [http://localhost:8080/health](http://localhost:8080/health)

Arrêt :

```bash
docker compose down
```

## 6) Vérification fonctionnelle

```bash
bash scripts/smoke_test.sh
```

Le script vérifie :
- disponibilité HTTP,
- endpoint de santé,
- continuité de service même si une instance applicative tombe.

## 7) Étapes TP recommandées

1. Déployer la stack
2. Vérifier la répartition de charge
3. Simuler la panne d’un nœud applicatif
4. Valider la continuité de service
5. Appliquer les mesures sécurité/conformité documentées
6. Produire les preuves (captures, logs, tests)

## 8) Limites de cette version

- Base de données en instance unique (la HA DB est documentée en trajectoire cible)
- Chiffrement TLS non activé par défaut en local (à activer en environnement d’intégration/production)

Voir `docs/architecture.md` pour les évolutions (Patroni/Keepalived, etc.).
