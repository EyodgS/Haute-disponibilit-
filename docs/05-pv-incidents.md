# Procès-verbal d'incidents — Phase 7

Ce document consigne les incidents détectés et diagnostiqués lors de la phase 7.

## Méthode

Pour chaque incident :
1. **Détection** — la sonde `check-dispo.sh` tourne en continu sur CLIENT
2. **Diagnostic** — analyse avec `journalctl`, `tcpdump`, `ip`, `nft`, stats HAProxy, logs VRRP
3. **Remédiation** — action corrective
4. **Action préventive** — pour éviter la récidive

---

## INC-01 — Arrêt brutal de WEB1

| Champ | Valeur |
|---|---|
| **Identifiant** | INC-01 |
| **Horodatage de détection** | <!-- À COMPLÉTER --> |
| **Symptôme observé** | <!-- À COMPLÉTER --> |
| **Impact mesuré** | <!-- À COMPLÉTER --> |
| **Diagnostic** | <!-- À COMPLÉTER --> |
| **Cause racine** | <!-- À COMPLÉTER --> |
| **Remédiation appliquée** | <!-- À COMPLÉTER --> |
| **Action préventive** | <!-- À COMPLÉTER --> |

---

## INC-02 à INC-06

À remplir au fur et à mesure.

---

## INC-01 — Arrêt brutal de WEB1 (VBoxManage poweroff)

| Champ | Valeur |
|---|---|
| **Identifiant** | INC-01 |
| **Horodatage de détection** | 2026-10-06 12:42:59 |
| **Symptôme observé** | Aucun — le service a continué à répondre en HTTPS (200 OK). La sonde n'a détecté aucune interruption. |
| **Impact mesuré** | 0 requête en échec — HAProxy a sorti WEB1 du pool en 11 s (inter 2s × fall 3 = 6 s théoriques + latence de check) |
| **Diagnostic** | 1. HAProxy log : `Server be_web/web1 is DOWN, reason: Layer4 timeout, check duration: 2002ms` — WEB1 ne répond plus aux sondes TCP<br>2. `ping 192.168.20.21` depuis LB1 : `Destination Host Unreachable` — la VM est bien éteinte<br>3. Service : `curl https://portail.novasante.lan/` retourne `200 OK` — WEB2 a pris le relais |
| **Cause racine** | Arrêt brutal de la VM WEB1 (simulé par `VBoxManage controlvm WEB1 poweroff`). Panne matérielle. |
| **Remédiation appliquée** | Rallumage de WEB1 par `VBoxManage startvm WEB1 --type headless`. Après 40 s, WEB1 est revenue UP, nginx + php-fpm actifs. Le service HTTPS répond toujours. |
| **Action préventive** | 1. HAProxy sort automatiquement WEB1 du pool (déjà en place ✅)<br>2. Supervision Prometheus/blackbox qui alerte si WEB1 reste DOWN > 5 min<br>3. Redondance de l'alimentation électrique si WEB1 est sur un site physique (hors maquette) |

### Anomalies détectées pendant le diagnostic (corrigées)

| Anomalie | Cause | Correction |
|---|---|---|
| `socat /run/haproxy/admin.sock: Connection refused` | Socket admin absent de la config | Ajout de `stats socket /run/haproxy/admin.sock mode 660 level admin` dans `global` |
| `HAProxy: sendmsg()/writev() failed in logger #1` | `/dev/log` non disponible (interférence journald) | Ajout de `/etc/rsyslog.d/49-haproxy.conf` pour rediriger `local0` et `local1` vers `/var/log/haproxy.log` |


### Anomalie critique détectée en INC-01

| Champ | Valeur |
|---|---|
| **Identifiant** | INC-01bis |
| **Découverte pendant** | Diagnostic INC-01 |
| **Symptôme** | `HAProxy: Failed to set up mount namespacing: /run/systemd/unit-root/var/lib/haproxy/dev/log: No such file or directory`. HAProxy refuse de démarrer. Service HTTPS complètement HS. |
| **Cause racine** | `/dev/log` (symlink vers `/run/systemd/journal/dev-log`) a été supprimé lors des manipulations rsyslog. HAProxy utilise `log /dev/log local0` dans sa config → si le socket n'existe pas, systemd ne peut pas monter le namespace → démarrage échoue. |
| **Diagnostic** | `ls -la /dev/log` → absent. `journalctl -u haproxy` → `status=226/NAMESPACE`. |
| **Remédiation appliquée** | `ln -sf /run/systemd/journal/dev-log /dev/log` puis `systemctl restart haproxy`. |
| **Action préventive** | 1. Ne jamais supprimer `/dev/log` (c'est un symlink système créé par systemd)<br>2. Ajouter un check de supervision qui vérifie `/dev/log`<br>3. Alternative : utiliser `log 127.0.0.1:514 local0` au lieu de `/dev/log` pour éviter la dépendance au socket Unix<br>4. Utiliser `systemd-tmpfiles --create` pour recréer les fichiers système si nécessaire |


---

## INC-02 — Mort de HAProxy sur LB1 (limite documentée)

| Champ | Valeur |
|---|---|
| **Identifiant** | INC-02 |
| **Horodatage de détection** | 2026-10-06 13:20:01 |
| **Symptôme observé** | HAProxy arrêté sur LB1, mais LB1 garde la VIP pendant plus de 90 secondes. Le service devient HS (502). |
| **Impact mesuré** | Service indisponible tant que HAProxy n'est pas redémarré manuellement OU tant qu'une autre panne ne force pas la bascule. |
| **Diagnostic** | 1. `journalctl -u keepalived` : `VRRP_Script(chk_haproxy) succeeded` — le script retourne toujours 0<br>2. `journalctl -u keepalived` : `(VI_LAN) ignoring tracked script chk_haproxy with weights due to SYNC group`<br>3. `journalctl -u keepalived` : `Warning - script chk_haproxy is not used` |
| **Cause racine** | **Bug connu de Keepalived 2.2.x** : quand un `vrrp_script` est utilisé dans un `vrrp_sync_group`, la directive `weight` est ignorée et le script n'est PAS exécuté périodiquement. Le script n'est appelé qu'une seule fois au démarrage. |
| **Remédiation appliquée** | Non résolu dans la maquette. Solutions proposées ci-dessous. |
| **Action préventive** | 1. **Watchdog externe** : timer systemd qui vérifie HAProxy toutes les 2 s et arrête keepalived si HAProxy est mort → bascule VRRP forcée<br>2. **Architecture alternative** : ne pas utiliser `vrrp_sync_group`, gérer les 2 instances VRRP indépendamment (mais perd la bascule synchronisée)<br>3. **Mise à jour Keepalived** : version 2.3.x corrige potentiellement ce bug |
| **Impact sur le TP** | Sur les 3 scénarios de panne demandés :<br>- ✅ Arrêt propre keepalived (validé Phase 3)<br>- ✅ Coupure brutale / poweroff LB1 (validé Phase 3)<br>- ❌ Mort de HAProxy (bug Keepalived)<br>**2/3 scénarios validés.** |

### Analyse approfondie — Pourquoi ce bug ?

Le `vrrp_sync_group` de Keepalived fonctionne sur un principe simple : **les instances membres basculent ensemble**. Pour garantir cette cohérence, Keepalived refuse d'appliquer des poids différents à chaque instance (car cela pourrait créer des états incohérents).

Mais il refuse AUSSI d'exécuter le script périodiquement, même quand on le place dans le groupe. C'est un comportement **contre-intuitif** qui n'est pas clairement documenté.

**Ce qu'on a testé (3 configurations) :**

| Config | Résultat |
|---|---|
| `track_script` dans chaque instance + `weight -60` | `ignoring tracked script due to SYNC group` → script ignoré |
| `track_script` dans le groupe | Script appelé une seule fois, pas de polling |
| Retirer le `weight` + `track_script` dans chaque instance | Aucun changement, script toujours ignoré |

**Verdict :** dans la version 2.2.7-1+b2 de Keepalived fournie par Debian 12, **un script de surveillance avec un sync_group ne fonctionne pas** pour forcer une bascule automatique.


---

## INC-02 — Mort de HAProxy sur LB1 (limite documentée)

| Champ | Valeur |
|---|---|
| **Identifiant** | INC-02 |
| **Horodatage de détection** | 2026-10-06 13:20:01 |
| **Symptôme observé** | HAProxy arrêté sur LB1, mais LB1 garde la VIP pendant plus de 90 secondes. Le service devient HS (502). |
| **Impact mesuré** | Service indisponible jusqu'à redémarrage manuel de HAProxy. |
| **Diagnostic** | 1. `journalctl -u keepalived` : `(VI_LAN) ignoring tracked script chk_haproxy with weights due to SYNC group`<br>2. `Warning - script chk_haproxy is not used`<br>3. Le script n'est appelé qu'une seule fois au démarrage, jamais en boucle |
| **Cause racine** | **Bug connu de Keepalived 2.2.x** (version Debian 12) : un `vrrp_script` avec `weight` est **ignoré** quand il est utilisé dans un `vrrp_sync_group`. Le script n'est pas exécuté périodiquement. |
| **Remédiation appliquée** | Non résolu dans la maquette. Solutions proposées ci-dessous. |
| **Action préventive** | 1. Watchdog externe (timer systemd)<br>2. Mise à jour Keepalived vers 2.3.x<br>3. Architecture avec instances VRRP indépendantes (sans sync_group) |

### Test empirique — 3 configurations testées

| Config | Résultat |
|---|---|
| `track_script` + `weight -60` dans chaque instance | Script ignoré (`ignoring tracked script due to SYNC group`) |
| `track_script` dans le groupe uniquement | Script appelé UNE fois, pas de polling |
| Retirer `weight` + garder `track_script` dans chaque instance | Script toujours ignoré |

**Verdict :** la version 2.2.7-1+b2 de Keepalived (Debian 12) ne supporte pas la surveillance périodique avec sync_group.

### Impact sur le TP

| Scénario de panne | Statut |
|---|---|
| Arrêt propre de keepalived | ✅ Validé (Phase 3) |
| Coupure brutale (poweroff LB1) | ✅ Validé (Phase 3) |
| Mort de HAProxy (processus) | ❌ Bug Keepalived — documenté |

**2/3 scénarios validés.** Cette limite est un vrai apprentissage d'admin sys : identifier les limites d'un outil et proposer des alternatives.

