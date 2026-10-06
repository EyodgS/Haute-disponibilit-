# RETEX — TP Haute Disponibilité NovaSanté (Phase 8)

## 1) Introduction

### Contexte du TP
Ce RETEX s’inscrit dans le TP de Haute Disponibilité réalisé pour le portail de prise de rendez-vous **NovaSanté**, avec un cadre orienté **continuité de service**, **sécurité**, **NIS2** et **RGPD**.

### Démarche globale
La démarche a suivi les phases prévues du TP : architecture, adressage, tests, incidents, exploitation, sécurité/conformité, puis synthèse des acquis et limites.

### Bilan d’avancement
- **7 phases sur 8 terminées**
- **2 scénarios de bascule validés sur 3** (limite documentée sur la mort de HAProxy avec Keepalived 2.2.x en `vrrp_sync_group`)

---

## 2) Erreurs techniques rencontrées

| # | Erreur | Phase | Symptôme | Cause | Correction | Leçon |
|---|---|---|---|---|---|---|
| 1 | `su` au lieu de `su -` | 1 | `nginx: commande introuvable` | PATH incomplet | `su -` (avec tiret) | Toujours utiliser `su -` |
| 2 | Heredoc mal fermé (`EOF }`) | 1 | Config nginx cassée | Faute de frappe | Réécrire le fichier | Vérifier avec `cat` après chaque heredoc |
| 3 | `dpkg-reconfigure` absent | 0 | SSH cassé | Paquet debconf non installé | `apt install debconf` | Ne pas supposer les outils installés |
| 4 | `killall` absent (psmisc) | 3 | `vrrp_script` désactivé silencieusement | Paquet `psmisc` non installé | Script basé sur `systemctl is-active` | Toujours tester les scripts en isolation |
| 5 | `machine-id` identiques | 0 | Conflits DHCP | Dé-clonage incomplet | `systemd-machine-id-setup` | Toujours vérifier après clonage |
| 6 | SSH root refusé | 1 | `Permission denied` | `PermitRootLogin no` | Créer user admin + clé | Utiliser un user admin dès le début |
| 7 | Mot de passe en clair dans HAProxy | 2 | Risque de fuite sur Git | Mauvais réflexe | Placeholder `__MDP__` | Ne JAMAIS commiter de secret |
| 8 | Config HAProxy en doublon | 4 | `'cookie' ignored` warning | `sed` mal ciblé | Supprimer la ligne en trop | Vérifier après chaque `sed` |
| 9 | `/dev/log` supprimé | 6 | HAProxy refuse de démarrer | Manipulation rsyslog | `ln -sf /run/systemd/journal/dev-log /dev/log` | Ne pas toucher aux fichiers système |
| 10 | `weight` ignoré dans `sync_group` | 7 | `vrrp_script` inefficace | Bug Keepalived 2.2.x | Documentation + limites | Vérifier les logs keepalived après chaque modif |
| 11 | Confusion Git Bash / VM (×5) | 4, 5, 6 | `sudo: command not found` | Prompt non vérifié | Toujours regarder `hostname` | Vérifier 2× avant `sudo` |
| 12 | Mauvaise VM (LB2 au lieu de WEB1) | 6 | Config appliquée au mauvais serveur | Inattention | Règle : `hostname` après SSH | Automatiser la vérification |
| 13 | `haproxy` restart sans test | 2 | Service coupé | Réflexe à acquérir | `haproxy -c` AVANT reload | Toujours valider avant de recharger |
| 14 | Corruption cert sans reload | 7 | Rien ne se passe | Cert en mémoire | `systemctl reload haproxy` | Reload nécessaire après modif TLS |
| 15 | Split-brain | 7 | Les 2 LB MASTER | Câble coupé | Rétablir lien | Vérifier la topologie après chaque test |

---

## 2bis) Métriques clés du TP

| Métrique | Objectif | Résultat observé | Conforme ? |
|---|---|---|---|
| Taux de disponibilité (Phase 7) | 99,9 % | 99,9 % | ✅ |
| RTO — Arrêt propre keepalived | < 30 s | 1,6 s | ✅ |
| RTO — Coupure brutale (poweroff) | < 30 s | 3,6 s | ✅ |
| RTO — Mort de HAProxy | < 30 s | non mesuré (bug Keepalived) | ⚠️ |
| RPO — Réplication rsync | < 5 min | < 90 s | ✅ |
| MAJ 1.0 → 1.1 sans interruption | 0 requête perdue | 1031/1031 réussies (100,000 %) | ✅ |
| Scénarios de bascule validés | 3/3 | 2/3 (limite Keepalived) | ⚠️ |

---

## 3) Erreurs méthodologiques

- **Ne pas vérifier l’état du lab avant chaque phase** → perte de temps
- **Ne pas committer assez souvent** → historique Git pas assez granulaire
- **Ne pas tester les scripts en isolation** → bugs découverts tardivement
- **Supposer que les VMs sont dans l’état attendu** → confusion LB1/LB2/WEB1/WEB2
- **Copier-coller sans comprendre** → risque de ne pas savoir expliquer en soutenance

---

## 4) Erreurs opérationnelles

- **Modification des configs directement sans backup** → perte de la version qui marchait
- **Pas de documentation au fil de l’eau** → oublis dans le PV
- **Ne pas relire les messages du formateur** → malentendus sur les objectifs

---

## 5) Ce qui a bien fonctionné

- Utilisation de `timeout` pour limiter les sondes
- Fichiers CSV conservés bruts (traçabilité)
- Documentation au fil du TP
- Git commits fréquents avec messages explicites
- Tests de non-régression après chaque phase

---

## 6) Améliorations identifiées (non implémentées)

| # | Amélioration | Priorité | Effort | Bénéfice |
|---|---|---|---|---|
| 1 | Watchdog externe pour HAProxy (timer systemd) | Haute | 15 min | Résout le bug Keepalived |
| 2 | Mise à jour Keepalived vers 2.3.x | Moyenne | 30 min | Corrige potentiellement le bug |
| 3 | Supervision Prometheus + Grafana (extension E1) | Haute | 2h | Visibilité temps réel |
| 4 | Redis pour sessions partagées (extension E4) | Moyenne | 1h | Supprime la limite sticky sessions |
| 5 | Base de données répliquée MariaDB (extension E2) | Moyenne | 2h | Cohérence des données |
| 6 | Centralisation rsyslog corrigée (`imudp`) | Basse | 30 min | Trace complète |
| 7 | Tests automatisés avec Ansible | Basse | 3h | Reproductibilité |
| 8 | Sauvegardes externalisées | Haute | 1h | Protège contre ransomware |
| 9 | `nopreempt` testé sur LB2 | Basse | 10 min | Stabilité |

---

## 7) Leçons apprises (résumé)

- **Toujours vérifier le prompt** avant les commandes sudo
- **Toujours tester les scripts en isolation** avant de les intégrer
- **Toujours valider la syntaxe** avant de recharger un service
- **Toujours sauvegarder les configs** avant modification
- **Toujours documenter au fil de l’eau**
- **Un TP est un exercice d’humilité** : on apprend plus de ses erreurs que de ses succès

---

## 8) Conclusion

Le bilan global est positif : **85 à 95 % des objectifs sont atteints**, avec des **limites assumées et documentées**.

Compétences consolidées pendant le TP :
- HAProxy (répartition, healthchecks, reload sécurisé)
- Keepalived / VRRP (bascule, priorités, limites en sync group)
- nftables (filtrage, NAT, flux VRRP)
- TLS (certificats, reload, diagnostic)
- rsync (réplication simple et limites RPO)

Ce qui serait fait différemment sur une prochaine itération :
- Mettre un **watchdog** dès le début
- Ajouter des **tests automatisés** plus tôt
- Déployer une **supervision centralisée** en continu

---

## 9) Compétences acquises

| Domaine | Compétences |
|---|---|
| Répartition de charge | HAProxy (frontend, backend, ACL, cookie, sonde HTTP, stats socket) |
| Haute disponibilité | Keepalived, VRRP, `vrrp_sync_group`, priorités, scripts de check |
| Pare-feu | nftables (tables, chaînes, filtrage, NAT, masquerade, protocole 112) |
| TLS | OpenSSL (AC interne, CSR, signature), HAProxy `bind ssl`, `curl -k` vs sans `-k` |
| Réplication | rsync + timer systemd, clés SSH restreintes (rrsync) |
| Système | systemd (services, timers), journalctl, apt, dépannage réseau |
| Git | Commits atomiques, branches, merge, résolution de conflits |
| Documentation | Markdown, PV de tests, PV d'incidents, procédures d'exploitation |

---

## 10) Références aux livrables

| Livrable | Fichier |
|---|---|
| Architecture | `docs/01-architecture.md` |
| Plan d'adressage + matrice de flux | `docs/02-plan-adressage.md` |
| Procédures d'exploitation | `docs/03-procedures.md` |
| PV de tests | `docs/04-pv-tests.md` |
| PV d'incidents (Phase 7) | `docs/05-pv-incidents.md` |
| Analyse des SPOF | `docs/tp-ha-07-spof-residuels.md` |
| RETEX (ce document) | `docs/07-retex.md` |
| Auto-évaluation | `docs/08-auto-evaluation.md` |
| Configurations | `configs/lb1/`, `configs/lb2/`, `configs/web1/`, `configs/web2/` |
| Mesures brutes | `mesures/` |
