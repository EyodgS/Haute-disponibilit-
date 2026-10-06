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


---

## INC-02 — Mort de HAProxy sur LB1 (limite documentée)

| Champ | Valeur |
|---|---|
| **Identifiant** | INC-02 |
| **Horodatage de détection** | 2026-10-06 13:20:01 |
| **Symptôme observé** | HAProxy arrêté sur LB1, mais LB1 garde la VIP pendant plus de 90 secondes. Le service devient HS (502). |
| **Impact mesuré** | Service indisponible jusqu'à redémarrage manuel de HAProxy. |
| **Diagnostic** | 1. `journalctl -u keepalived` : `(VI_LAN) ignoring tracked script chk_haproxy with weights due to SYNC group`<br>2. `Warning - script chk_haproxy is not used`<br>3. Le script n'est appelé qu'une seule fois au démarrage |
| **Cause racine** | **Bug connu de Keepalived 2.2.x** (Debian 12) : un `vrrp_script` avec `weight` est ignoré quand il est utilisé dans un `vrrp_sync_group`. |
| **Remédiation appliquée** | Non résolu. Solutions proposées : watchdog externe (timer systemd), mise à jour Keepalived 2.3.x, ou instances VRRP indépendantes. |
| **Action préventive** | Documenter les limites de Keepalived et prévoir un watchdog externe en production |

### Impact sur le TP

| Scénario de panne | Statut |
|---|---|
| Arrêt propre keepalived | ✅ Validé (Phase 3) |
| Coupure brutale (poweroff LB1) | ✅ Validé (Phase 3) |
| Mort de HAProxy (processus) | ❌ Bug Keepalived — documenté |

**2/3 scénarios validés.**


---

## INC-03 — Split-brain (coupure du lien HA-LAN sur LB1)

| Champ | Valeur |
|---|---|
| **Identifiant** | INC-03 |
| **Horodatage de détection** | <!-- À COMPLÉTER --> |
| **Symptôme observé** | <!-- À COMPLÉTER selon résultat --> |
| **Impact mesuré** | <!-- À COMPLÉTER --> |
| **Diagnostic** | 1. `ip -br link show enp0s8` sur LB1 : interface DOWN<br>2. `ip -br addr \| grep 192.168.10.100` sur LB2 : Vérifier si VIP apparaît (split-brain) |
| **Cause racine** | Coupure physique du lien réseau entre LB1 et LB2. Chacun croit être seul sur le réseau → les deux deviennent MASTER. |
| **Remédiation appliquée** | `VBoxManage controlvm LB1 setlinkstate2 on` → lien rétabli → un seul MASTER après convergence VRRP. |
| **Action préventive** | 1. `vrrp_sync_group` (déjà en place) : synchronise les instances<br>2. Détection par supervision (alerte si les 2 LB ont la VIP)<br>3. Fencing (STONITH) en production : tuer le nœud isolé<br>4. Réseau de heartbeat dédié (déjà HA-SYNC) : empêche le split-brain sur HA-LAN<br>5. `advert_int` court pour détecter vite |


### Résultats observés pour INC-03

| Champ | Valeur |
|---|---|
| **Horodatage de détection** | 2026-10-06 13:34:05 (5s après injection) |
| **Symptôme observé** | Service HTTPS indisponible pendant 15-20 secondes. `curl https://portail.novasante.lan/` timeout. |
| **Impact mesuré** | Interruption totale pendant la durée du split-brain. |
| **Diagnostic confirmé** | 1. LB1 : `enp0s8 DOWN` (`NO-CARRIER`) → interface réseau coupée<br>2. LB2 : `192.168.10.100` apparaît sur enp0s8 → **LB2 devient MASTER**<br>3. LB1 : garde aussi la VIP sur une interface DOWN → **SPLIT-BRAIN CONFIRMÉ** |
| **Remédiation** | `VBoxManage controlvm LB1 setlinkstate2 on` → convergence automatique : LB1 reprend MASTER (priorité 150 > 100), LB2 rend la VIP |
| **Cause racine (réelle)** | Le `vrrp_sync_group` de Keepalived ne gère PAS le cas où un lien réseau est coupé sur un seul nœud. Chaque LB croit être seul → les deux deviennent MASTER. |

### Analyse approfondie

Le split-brain s'est produit car :
- LB1 a perdu son lien HA-LAN (`enp0s8` DOWN)
- LB1 est resté MASTER (car il n'a pas perdu ses autres liens)
- LB2 n'a plus reçu les annonces VRRP de LB1 → après `advert_int × 3` = 3s, il s'est déclaré MASTER
- Les deux portent la VIP `192.168.10.100`

**Conséquence pour le client :**
- Le CLIENT envoie une requête vers `192.168.10.100`
- L'ARP peut renvoyer l'adresse MAC de LB1 (interface DOWN → pas de réponse) ou de LB2 (réponse OK)
- → Le service est **intermittent** puis complètement HS

### Action préventive (recommandations)

| # | Mesure | Coût |
|---|---|---|
| 1 | **`nopreempt` sur LB2** : empêche LB2 de prendre la VIP si LB1 est encore MASTER | Faible |
| 2 | **Fencing (STONITH)** : tuer automatiquement le nœud isolé | Élevé |
| 3 | **Détection active** : supervision qui alerte si les 2 LB portent la VIP | Moyen |
| 4 | **Réseau de heartbeat redondant** : 2 liens entre LB1 et LB2 (LAN + SYNC) | Moyen |
| 5 | **Réduire `advert_int`** à 0.5s pour détecter plus vite | Faible |

**Dans un contexte de production :** on utiliserait un cluster Pacemaker + Corosync avec fencing (IPMI, iLO), qui gère nativement ces cas.


---

## INC-04 — Disque plein sur WEB1

| Champ | Valeur |
|---|---|
| **Identifiant** | INC-04 |
| **Horodatage de détection** | 2026-10-06 13:38 (injection) |
| **Symptôme observé** | Disque de WEB1 à 100% après création d'un fichier de 6 Go. La sonde `/health.php` a commencé à échouer (impossible d'écrire dans `/var/www/data`). |
| **Impact mesuré** | Aucune interruption visible côté utilisateur (WEB2 prenait le relais via HAProxy). |
| **Diagnostic** | 1. `df -h /` → 100% d'utilisation<br>2. `/var/www/data` supprimé par le système suite au disque plein<br>3. `curl http://192.168.20.21/health.php` → erreur 5xx ou timeout<br>4. HAProxy `show stat` → WEB1 sorti du pool automatiquement |
| **Cause racine** | Fichier temporaire de 6 Go créé via `fallocate -l 6G`. Simule une **panne logicielle** (accumulation de fichiers, logs non rotés, uploads non nettoyés). |
| **Remédiation appliquée** | `sudo rm -f /var/fill.tmp` → disque libéré (26%) → `/var/www/data` recréé avec permissions `www-data:www-data` → sonde repasse à `OK` → WEB1 réintégré dans HAProxy |
| **Action préventive** | 1. Sonde honnête `/health.php` qui teste l'écriture disque ✅<br>2. Alerte supervision si l'utilisation disque > 80%<br>3. `logrotate` pour rotation automatique des logs<br>4. `systemd-tmpfiles` pour nettoyer `/tmp` et `/var/tmp`<br>5. Prometheus + node_exporter pour monitoring disque |

### Analyse — Importance de la sonde honnête

**Ce cas illustre le rôle critique de la sonde honnête :**

- Une sonde **statique** `/health` aurait continué à répondre `200 OK` → HAProxy n'aurait pas sorti WEB1 du pool → les utilisateurs auraient eu des erreurs 500/502
- La sonde **honnête** `/health.php` teste l'écriture dans `/var/www/data` → retourne `503` → HAProxy sort WEB1 automatiquement

**Résultat :** service maintenu **sans interruption** pour les utilisateurs grâce à WEB2.

### Résultats observés

- **Sonde avant correction :** erreur (disque plein)
- **WEB1 dans HAProxy avant correction :** sorti du pool
- **Service HTTPS avant correction :** 200 OK (via WEB2)
- **Sonde après correction :** `OK`
- **WEB1 dans HAProxy après correction :** `UP`
- **Fichiers préservés dans `/var/www/data` après recréation :** `rpo-final.txt`, `test-auto.txt`, `test-replication.txt`


---

## INC-05 — Perte de la réplication rsync (coupure HA-SYNC sur WEB1)

| Champ | Valeur |
|---|---|
| **Identifiant** | INC-05 |
| **Horodatage de détection** | 2026-10-06 13:53:37 |
| **Symptôme observé** | Les logs de `rsync-data.service` sur WEB1 montrent un échec répété : `ssh: connect to host 10.99.99.22 port 22: No route to host`. La réplication est cassée. |
| **Impact mesuré** | RPO non respecté : les fichiers déposés sur WEB1 pendant la coupure ne seront jamais répliqués vers WEB2. Incohérence de données potentielle si WEB1 tombe et que la VIP bascule sur WEB2. |
| **Diagnostic** | 1. `ip -br link show enp0s9` sur WEB1 → DOWN (NO-CARRIER)<br>2. `systemctl status rsync-data.service` → `failed (Result: exit-code)`<br>3. `journalctl -u rsync-data.service` → `ssh: connect to host 10.99.99.22 port 22: No route to host`<br>4. Sortie rsync : `rsync error: error in rsync protocol data stream (code 12)` |
| **Cause racine** | Coupure du lien réseau HA-SYNC (`VBoxManage controlvm WEB1 setlinkstate3 off`). Le rsync ne peut plus joindre WEB2 sur 10.99.99.22:22. **Aucune alerte automatique** ne signale l'échec. |
| **Remédiation appliquée** | 1. `VBoxManage controlvm WEB1 setlinkstate3 on` → lien rétabli<br>2. `systemctl start rsync-data.service` → exécution manuelle<br>3. Le prochain cycle du timer réplique les fichiers en attente |
| **Action préventive** | 1. **Timer avec `OnFailure=`** : déclencher une alerte systemd quand rsync échoue<br>2. **Supervision dédiée** : vérifier périodiquement que les fichiers de WEB1 sont bien sur WEB2<br>3. **Alerte RPO** : si un fichier n'est pas répliqué en < 5 min, alerter<br>4. **Lien de réplication redondant** : utiliser 2 chemins réseau<br>5. **Journalisation centralisée** : remonter les échecs rsync (dépend de la correction de 6.6) |

### Analyse — Limite structurelle de la réplication unidirectionnelle

**Ce cas illustre trois limites de notre architecture :**

1. **Réplication WEB1 → WEB2 uniquement :** un fichier déposé sur WEB2 n'est jamais répliqué vers WEB1. Dans notre test, l'upload a été routé vers WEB2 (roundrobin), donc le fichier est resté sur WEB2 uniquement — c'est le comportement attendu.

2. **Aucune détection d'échec :** si le lien tombe, le timer échoue silencieusement. Aucune alerte n'est levée.

3. **RPO non garanti :** pendant une panne de lien, les fichiers sur WEB1 ne sont pas répliqués. Si WEB1 tombe, ces fichiers sont perdus jusqu'à ce que le lien revienne et que le rsync rattrape son retard.

**En production, on utiliserait :**
- Un service de monitoring qui vérifie que `rsync-data.timer` a bien tourné dans les 5 dernières minutes
- Une alerte Prometheus `rsync_last_success_timestamp > 300`
- Une supervision du RPO côté application

### Résultat observé

- **Fichier déposé via VIP sur :** WEB2 (roundrobin)
- **Fichier sur WEB1 :** ABSENT
- **Fichier sur WEB2 :** PRESENT
- **Statut rsync sur WEB1 pendant injection :** FAILED (exit code 12)
- **Logs rsync :** `ssh: connect to host 10.99.99.22 port 22: No route to host`
- **Après remédiation :** rsync reprend, fichier forcé sur WEB1 répliqué vers WEB2


---

## INC-06 — Corruption du certificat TLS sur LB1

| Champ | Valeur |
|---|---|
| **Identifiant** | INC-06 |
| **Horodatage de détection** | 2026-10-06 13:58:22 |
| **Symptôme observé** | Tentative de reload de HAProxy après corruption du certificat. Le reload échoue (`Job for haproxy.service failed`), MAIS HAProxy reste actif et le service continue à répondre en HTTPS. |
| **Impact mesuré** | **Aucune interruption de service.** Le mécanisme de "safe reload" de HAProxy a maintenu l'ancien processus en mémoire, qui utilise toujours l'ancien certificat (valide). |
| **Diagnostic** | 1. `systemctl reload haproxy` → `Job for haproxy.service failed`<br>2. `journalctl -u haproxy` → `Reload failed for haproxy.service`<br>3. `systemctl is-active haproxy` → **`active`** (l'ancien process tourne toujours)<br>4. `curl https://portail.novasante.lan/` → **`HTTP/1.1 200 OK`** |
| **Cause racine** | Fichier `/etc/ssl/novasante/portail.pem` remplacé par un contenu invalide (`CORROMPU`). HAProxy refuse de charger le nouveau certificat mais **ne tue pas l'ancien processus** : c'est un mécanisme de protection contre les erreurs de configuration. |
| **Remédiation appliquée** | `cp /tmp/portail.pem.bak /etc/ssl/novasante/portail.pem` + `systemctl restart haproxy` → certificat restauré, HAProxy redémarre avec le bon cert. |
| **Action préventive** | 1. **Surveillance de l'expiration des certificats** : alerte 30j avant expiration<br>2. **Test de reload avant production** : `haproxy -c -f /etc/haproxy/haproxy.cfg` avant tout reload<br>3. **Sauvegarde automatique** des certificats avant modification<br>4. **Validation du certificat** : `openssl x509 -in portail.crt -noout -checkend 2592000` (30 jours)<br>5. **Déploiement progressif** : mettre à jour LB2 d'abord, tester, puis LB1 |

### Analyse — Deux scénarios de corruption

**Le reload échoue proprement (ce qu'on a observé) :**
- HAProxy refuse de charger le nouveau cert
- L'ancien processus continue de tourner avec l'ancien cert
- **Service non interrompu** ✅

**Le restart est brutal (plus dangereux) :**
- systemd tue l'ancien processus AVANT de démarrer le nouveau
- Si le cert est invalide → le nouveau processus ne peut pas démarrer
- **Service complètement HS** ❌

**Leçon :**
- Un `reload` de HAProxy est **toujours plus sûr** qu'un `restart` : il ne tue l'ancien process qu'après avoir validé le nouveau
- **Toujours tester `haproxy -c -f`** avant un reload
- **Surveiller l'expiration** des certificats : c'est le seul cas où le reload peut échouer sans qu'on s'en aperçoive

### Résultat observé

- **Reload avec cert corrompu :** FAILED (`Job for haproxy.service failed`)
- **HAProxy pendant l'incident :** `active` (ancien process en mémoire)
- **Service HTTPS pendant l'incident :** `HTTP/1.1 200 OK` (ancien cert utilisé)
- **Après remédiation (restart) :** service rétabli avec le bon cert

