# Bilan de résilience : Comportement face aux 6 pannes (Phase 7)

## Tableau de synthèse

| # | Panne | Ce qui se passe | Verdict |
|---|---|---|---|
| 1 | Coupure brutale LB1 | LB2 prend la VIP en 3,6s. Service maintenu. | ✅ Marche parfaitement |
| 2 | Nginx arrêté sur WEB2 | HAProxy sort WEB2 du pool en 6s. WEB1 prend tout. | ✅ Marche parfaitement |
| 3 | LB1 "gelée" (pause) | LB2 ne reçoit plus d'annonces VRRP, prend la VIP. | ✅ Marche parfaitement |
| 4 | Disque plein sur WEB1 | La sonde `/health.php` renvoie 503. WEB1 est éjecté. | ✅ Marche parfaitement |
| 5 | Coupure HA-SYNC | VRRP continue (passe par LAN/DMZ). MAIS rsync casse. | ⚠️ Service OK, mais RPO en danger |
| 6 | Erreur syntaxe HAProxy | HAProxy refuse de démarrer. ET LB1 garde la VIP. | ❌ Le service tombe (Bug Keepalived) |

## Détail des comportements observés (Préparation Soutenance)

### Panne 1 : Coupure brutale de LB1 (Poweroff)

**Comportement :** LB1 s'éteint. LB2 ne reçoit plus les annonces VRRP (224.0.0.18) pendant 3 secondes. LB2 se déclare MASTER et prend les VIPs (192.168.10.100 et 192.168.20.100).

**Impact :** Le service est coupé pendant 3,6 secondes (le temps du timeout VRRP).

**Argumentaire pour l'oral :** C'est le scénario nominal de la Phase 3. Le RTO mesuré est de 3,6s, ce qui respecte l'objectif de < 30s.

### Panne 2 : Nginx arrêté sur WEB2

**Comportement :** HAProxy teste `/health.php` toutes les 2s. Au bout de 3 échecs (6s), HAProxy marque WEB2 comme DOWN. Tout le trafic va sur WEB1.

**Impact :** 0 interruption pour l'utilisateur. Le client bascule sur WEB1 grâce aux sticky sessions.

**Argumentaire pour l'oral :** Preuve que la sonde de santé fonctionne. WEB2 est sorti du pool sans que l'utilisateur ne s'en rende compte.

### Panne 3 : LB1 gelée (Pause)

**Comportement :** C'est une "panne molle". LB1 est allumée mais ne répond plus (ni au ping, ni aux annonces VRRP). LB2 ne reçoit plus rien et prend le relais.

**Impact :** Bascule automatique.

**Argumentaire pour l'oral :** Contrairement au poweroff, la machine est toujours allumée mais complètement figée. VRRP ne fait pas la différence, il bascule car il n'entend plus le Master.

### Panne 4 : Disque plein sur WEB1 (LA PANNE CRUCIALE)

**Comportement :** Le script remplit le disque. La sonde `/health.php` (qui vérifie si on peut écrire dans `/var/www/data`) échoue et renvoie 503 Service Unavailable. HAProxy sort WEB1 du pool.

**Impact :** 0 interruption. WEB2 prend le relais.

**Argumentaire pour l'oral :** C'est la panne la plus discriminante. Si on avait gardé une sonde statique `/health`, HAProxy aurait continué à envoyer du trafic sur WEB1 qui aurait renvoyé des erreurs 500. Grâce à notre sonde honnête, WEB1 a été éjecté.

### Panne 5 : Coupure du lien HA-SYNC

**Comportement :** LB1 et LB2 ne peuvent plus communiquer sur le réseau d'admin (10.99.99.x). MAIS le VRRP passe par HA-LAN et HA-DMZ (qui sont toujours up). Donc pas de bascule VRRP. Le timer rsync sur WEB1 ne peut plus joindre WEB2. La réplication casse.

**Impact :** Le service web fonctionne. Mais le RPO n'est plus garanti. Pas d'alerte automatique (limite).

**Argumentaire pour l'oral :** Le service est maintenu, mais c'est une panne silencieuse. Nous avons documenté le fait que la réplication est cassée et que sans supervision, on ne le verrait pas.

### Panne 6 : Erreur de syntaxe HAProxy (LE BUG ASSUMÉ)

**Comportement :** Le script injecte une faute (`roundrobbin`). HAProxy refuse de redémarrer sur LB1 (il est failed). Théoriquement, le `vrrp_script chk_haproxy` devrait détecter qu'HAProxy est mort et faire basculer LB1 en état FAULT. MAIS à cause du bug de Keepalived 2.2.x (script ignoré dans le sync_group), LB1 garde la VIP. Le service est complètement HS (erreur 502).

**Impact :** Coupure totale jusqu'à réparation manuelle.

**Argumentaire pour l'oral (Honnêteté) :** C'est notre limite majeure. Keepalived a un bug et ignore notre script de surveillance. Le service est tombé. Nous avons identifié la cause (logs Keepalived), documenté le bug, et proposé un watchdog systemd comme correctif. En production, ce scénario aurait alerté immédiatement.
