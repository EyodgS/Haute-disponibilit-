# TP-HA-01 — Architecture cible

## Objectif

Fournir une plateforme web tolérante aux pannes avec bascule automatique des load balancers.

## Topologie

- 2 load balancers (`LB1`, `LB2`) en redondance VRRP (Keepalived)
- 2 serveurs web (`WEB1`, `WEB2`) derrière HAProxy
- 1 poste `CLIENT` (`192.168.10.50`) pour les vérifications

Flux principal:

`CLIENT -> VIP 192.168.10.100 -> HAProxy (LB actif) -> WEB1/WEB2`

## Technologies

- **HAProxy** : répartition de charge HTTP
- **Keepalived (VRRP)** : bascule LB1/LB2 avec VIP
- **nginx + php-fpm** : service web sur WEB1/WEB2
- **nftables** : filtrage réseau sur chaque VM

## Phase 4 — Gestion des sessions utilisateur

### Comparatif des 3 solutions

| Solution | Avantages | Inconvénients | Impact sur la disponibilité |
|---|---|---|---|
| **(a) Sticky sessions (cookie HAProxy)** | Simple à implémenter, aucune modification applicative, aucune dépendance externe | Si le serveur tombe, le client perd sa session. Déséquilibre possible si les clients sont collants sur un même serveur | Bonne tant que le serveur reste up. Perte de session en cas de bascule |
| **(b) Session partagée (Redis/memcached)** | Session persistante même si un serveur tombe. Répartition équilibrée possible | Nouveau composant à déployer et à rendre hautement disponible. Latence réseau ajoutée. Redis devient un SPOF si non redondé | Meilleure à long terme, mais introduit un nouveau SPOF (Redis) |
| **(c) Session sans état (JWT)** | Aucun stockage côté serveur. Scalabilité horizontale parfaite | Refonte applicative nécessaire. Révocation de token complexe. Taille du token dans chaque requête | Excellente côté serveur, mais complexité applicative |

### Choix retenu : **(a) Sticky sessions par cookie HAProxy**

**Justification :** dans le cadre du TP, la solution (a) est la plus rapide à implémenter et ne nécessite aucune modification de l'application PHP. Elle résout le problème de session pour 99 % des cas (client qui reste sur le même serveur). Le compromis assumé est la perte de session en cas de bascule — acceptable pour un portail de prise de rendez-vous où l'utilisateur peut se reconnecter.

**Limite assumée :** en production, la solution (b) avec Redis serait préférable pour une vraie persistance. C'est l'extension E4 du sujet.