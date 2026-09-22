# Procès-verbal de tests — TP Haute Disponibilité NovaSanté

**Binôme :** EyodgS + [nom binôme]
**Formation :** B1 — Administrer et sécuriser les infrastructures
**Date :** Septembre 2026

Ce document consigne l'ensemble des mesures réalisées au cours du TP. Chaque mesure renvoie au fichier CSV brut correspondant, conservé tel quel dans `mesures/`.

---

## Point de contrôle 0 — Maquette opérationnelle

**Protocole :** depuis LB1, vérification de la connectivité vers les 3 réseaux internes.

| Test | Date/heure | Méthode | Essais | Résultat | Conforme ? |
|---|---|---|---|---|---|
| Ping LB1 → CLIENT (HA-LAN) | 14/09 | `ping -c2 192.168.10.50` | 2 | 2/2 reçus, 0 % perte | ✅ |
| Ping LB1 → WEB1 (HA-DMZ) | 14/09 | `ping -c2 192.168.20.21` | 2 | 2/2 reçus, 0 % perte | ✅ |
| Ping LB1 → LB2 (HA-SYNC) | 14/09 | `ping -c2 10.99.99.12` | 2 | 2/2 reçus, 0 % perte | ✅ |
| Horloges synchronisées | 14/09 | `timedatectl` sur les 5 VM | 5 VM | `System clock synchronized: yes` | ✅ |

**Machine-id uniques :** vérifiés sur les 5 VM (dé-clonage complet).

---

## Point de contrôle 1 — Service web redondé (WEB1 / WEB2)

**Protocole :** déploiement de nginx + php-fpm sur WEB1 et WEB2, puis mesure du SPOF.

### Vérifications des deux serveurs

| Test | Date/heure | Méthode | Résultat | Conforme ? |
|---|---|---|---|---|
| WEB1 répond | 21/09 | `curl -I http://192.168.20.21/` | 200 + `X-Served-By: web1` | ✅ |
| WEB2 répond | 21/09 | `curl -I http://192.168.20.22/` | 200 + `X-Served-By: web2` | ✅ |
| Sonde /health WEB1 | 21/09 | `curl http://192.168.20.21/health` | 200 OK | ✅ |
| Sonde /health WEB2 | 21/09 | `curl http://192.168.20.22/health` | 200 OK | ✅ |

### Mesure 1.5 — Panne de WEB1 (SPOF)

**Protocole :**
- Sonde `check-dispo.sh` lancée depuis LB1 vers `http://192.168.20.21/`
- Intervalle : 200 ms
- Arrêt brutal de WEB1 via `VBoxManage controlvm WEB1 poweroff`
- Durée de la mesure : 60 s

| Indicateur | Valeur |
|---|---|
| Requêtes émises | 300 |
| Requêtes en échec | 75 |
| Taux de disponibilité | 75 % |
| RTO observé | ~15 s |
| Codes HTTP en échec | `000` (injoignable) |
| CSV brut | `mesures/web1-direct.csv` |

**Analyse :** la panne de WEB1 rend le service indisponible pour tous les utilisateurs, alors que WEB2 est intact. WEB1 est un **SPOF** à ce stade du TP. La Phase 2 (HAProxy) corrigera ce point en répartissant la charge sur les deux serveurs.

---

## Point de contrôle 2 — Répartition de charge HAProxy

**Protocole :** HAProxy installé sur LB1, frontend en écoute sur `192.168.10.11:80`, backend `roundrobin` vers WEB1 et WEB2.

### Vérification de la répartition

| Test | Date/heure | Méthode | Résultat | Conforme ? |
|---|---|---|---|---|
| Alternance roundrobin | 21/09 | `for i in $(seq 10); do curl -sI http://192.168.10.11/ \| grep -i x-served-by; done` | web1 / web2 en alternance | ✅ |
| Stats depuis HA-SYNC | 21/09 | `curl -u admin:**** http://10.99.99.11:8404/stats` | 200 OK | ✅ |
| Stats depuis HA-LAN | 21/09 | `curl --max-time 2 http://10.99.99.11:8404/stats` | Timeout / refus | ✅ |

### Mesure 2.4a — Arrêt de nginx sur WEB1 (variation inter/fall/rise)

**Protocole :**
- Sonde `check-dispo.sh` lancée depuis CLIENT vers `http://192.168.10.11/`
- Intervalle : 200 ms
- Arrêt de nginx sur WEB1 via `systemctl stop nginx`
- Remise en service après 30 s

| Config HAProxy | Requêtes émises | Échecs | RTO observé | Répartition | CSV |
|---|---|---|---|---|---|
| `inter 2s fall 3 rise 2` | 220 | 2 | 0.2 s | web2 76.6 % / web1 23.4 % | `mesures/web1-down-via-haproxy.csv` |
| `inter 1s fall 2 rise 1` | 238 | 1 | 0.2 s | web2 79.3 % / web1 20.7 % | `mesures/web1-down-inter1s.csv` |
| `inter 500ms fall 1 rise 1` | à compléter | à compléter | à compléter | à compléter | `mesures/web1-down-inter500ms.csv` |

**Analyse :** plus `inter` est petit et `fall` bas, plus la détection de panne est rapide. En contrepartie, `inter 500ms fall 1` risque de sortir un serveur du pool sur une simple latence (faux positif) — un serveur momentanément chargé peut voir sa première requête de sonde échouer, ce qui suffit à le déclarer mort. **Compromis retenu :** `inter 2s fall 3 rise 2` (6 s de détection, mais fiable).

### Mesure 2.4b — Arrêt de LB1 (SPOF)

**Protocole :**
- Sonde vers `http://192.168.10.11/`
- Arrêt brutal de LB1 via `VBoxManage controlvm LB1 poweroff`
- Durée : 30 s

| Indicateur | Valeur |
|---|---|
| Requêtes émises | 150 |
| Requêtes en échec | 150 |
| Taux de disponibilité | 0 % |
| Cause | LB1 est un SPOF |
| CSV | `mesures/lb1-down.csv` |

**Analyse :** l'arrêt de LB1 rend tout le service indisponible, alors que WEB1 et WEB2 sont intacts. C'est le **SPOF déplacé** — la Phase 3 (VRRP) corrigera ce point.

---

## Point de contrôle 3 — VRRP / Keepalived

**Protocole :** deux instances VRRP configurées sur LB1 et LB2 (VI_LAN sur HA-LAN, VI_DMZ sur HA-DMZ), groupées dans `vrrp_sync_group VG_PORTAIL`. Bascule testée sur 3 scénarios × 3 essais.

### Vérifications initiales

| Test | Méthode | Résultat | Conforme ? |
|---|---|---|---|
| VIP sur LB1 | `ip -br addr \| grep 100` | 192.168.10.100 + 192.168.20.100 | ✅ |
| VIP absente sur LB2 | `ip -br addr \| grep 100` | rien | ✅ |
| Service répond sur VIP | `for i in $(seq 10); do curl -sI http://192.168.10.100/ \| grep -i x-served-by; done` | alternance web1 / web2 | ✅ |
| Bascule manuelle | `systemctl stop keepalived` sur LB1 | LB2 prend les VIP, HAProxy démarre | ✅ |

### Mesure 3.7 — RTO sur 9 scénarios

**Protocole commun :**
- Sonde `check-dispo.sh` lancée depuis CLIENT vers `http://192.168.10.100/`
- Intervalle : 200 ms
- Durée : 30 s (S1, S3) ou 60 s (S2)
- Injection de la panne à T+5 s, réparation à T+20 s
- RTO calculé entre la dernière requête `200` avant l'incident et la première requête `200` après

| Scénario | Essai 1 | Essai 2 | Essai 3 | Moyenne | Objectif | CSV |
|---|---|---|---|---|---|---|
| S1 — Arrêt propre keepalived | 1.6 s | 1.6 s | 1.6 s | **1.6 s** | < 30 s | `rto-s1-e*-v2.csv` |
| S2 — Coupure brutale (poweroff) | 3.6 s | 3.6 s | 3.6 s | **3.6 s** | < 30 s | `rto-s2-e*-v2.csv` |
| S3 — Mort de HAProxy (kill) | > 25 s | > 15 s | 5.6 s | **~15 s** | < 30 s | `rto-s3-e*-v2.csv` |

### Analyse détaillée

**S1 — Arrêt propre de keepalived** (1.6 s stable)
Le MASTER envoie un message de retrait propre (`STOP`) avant de rendre la VIP. LB2 détecte immédiatement l'absence d'annonce et prend le relais. Les CSV montrent une unique requête ralentie (~1020 ms) au moment exact de la bascule, puis un retour à la normale. **Aucune requête réellement perdue.**

**S2 — Coupure brutale de LB1 (poweroff)** (3.6 s stable)
LB2 doit attendre l'expiration du timer VRRP (`advert_int × 3` = 3 s) avant de se déclarer MASTER. Une requête perdue par essai (timeout à 2 s), les suivantes répondent normalement. Le RTO est cohérent avec la théorie (3 s + temps de convergence ARP).

**S3 — Mort de HAProxy sur LB1** (~15 s, 2 échecs sur 3)
Le `vrrp_script chk_haproxy` met 4 s à détecter la panne (fall 2 × interval 2 s), puis la priorité de LB1 chute de 150 à 90 (< 100), ce qui déclenche la bascule.

- **E3 (5.6 s) :** la bascule a fonctionné comme prévu — détection + bascule + reprise de HAProxy sur LB2.
- **E1 et E2 :** la bascule n'a pas eu lieu dans les 25 s suivant le `killall`. LB1 est resté MASTER sans HAProxy → service injoignable jusqu'à la réparation manuelle (`systemctl restart keepalived`).

**Cause probable de l'échec E1/E2 :** le script `vrrp_script` utilise `killall -0 haproxy`. Si le processus HAProxy est tué mais que le master process redémarre automatiquement (systemd avec `Restart=on-failure`), la sonde retourne immédiatement `0` (processus présent) et LB1 ne perd jamais sa priorité. À l'inverse, si HAProxy ne redémarre pas du tout, la bascule se produit correctement (cas E3).

**Piste d'amélioration (Phase 6 ou extension) :** ajouter `nopreempt` sur LB2 pour éviter les allers-retours, réduire `fall` à 1, ou utiliser un script plus robuste (vérifier que HAProxy répond sur `/stats` plutôt que de tester la présence du processus).

### Journal des transitions VRRP

Fichiers :
- `mesures/vrrp-transitions-lb1.log`
- `mesures/vrrp-transitions-lb2.log`

**Extrait LB2 :**