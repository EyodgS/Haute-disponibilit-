# Procédures d'exploitation

Ce document décrit les procédures opérationnelles du portail NovaSanté.

## 1. Mise à jour applicative sans interruption

**Objectif :** passer d'une version N à N+1 sans aucune requête perdue.

**Prérequis :**
- Accès SSH aux VM LB1, WEB1, WEB2, CLIENT
- Socket admin HAProxy actif
- LB1 en état MASTER

**Procédure :**

1. Lancer la sonde sur CLIENT : `timeout 300 bash ./scripts/check-dispo.sh http://192.168.10.100/ 0.2 mesures/maj.csv`

2. Drain WEB1 (depuis LB1) : `echo "set server be_web/web1 state drain" | socat stdio /run/haproxy/admin.sock`

3. Vérifier que WEB1 ne reçoit plus de trafic : `echo "show stat" | socat stdio /run/haproxy/admin.sock | grep "be_web,web1"`

4. Mettre à jour WEB1 : `ssh -p 2223 root@localhost "echo '1.1' > /var/www/html/version.txt"`

5. Remettre WEB1 en service : `echo "set server be_web/web1 state ready" | socat stdio /run/haproxy/admin.sock`

6. Répéter les étapes 2 à 5 sur WEB2 (remplacer `web1` par `web2`)

7. Arrêter la sonde avec Ctrl+C. Vérifier le bilan : 100,000 % attendu.

**Rollback :** restaurer `version.txt.bak` et relancer la procédure.

## 2. Bascule manuelle planifiée (LB1 → LB2)

1. `ssh -p 2221 root@localhost "systemctl stop keepalived"`
2. Vérifier que LB2 a pris les VIP : `ssh -p 2222 root@localhost "ip -br addr | grep 100"`
3. Vérifier que le service répond : `curl -I http://192.168.10.100/`
4. Intervenir sur LB1
5. `ssh -p 2221 root@localhost "systemctl start keepalived"`
6. Vérifier que LB1 a repris les VIP

## 3. Retour arrière (rollback)

1. Identifier le problème
2. Drain les serveurs impactés
3. `cp /var/www/html/version.txt.bak /var/www/html/version.txt`
4. Remettre en service (`ready`)
5. Vérifier avec la sonde

## 4. Remise en service après panne

1. Redémarrer la VM : `VBoxManage startvm <nom> --type headless`
2. Vérifier les services : `systemctl is-active haproxy keepalived nginx php8.2-fpm`
3. Vérifier le réseau : `ip -br addr`
4. Vérifier la réplication (WEB1/WEB2)
5. Vérifier l'état VRRP (LB1/LB2)
6. Vérifier le service : `curl -I http://192.168.10.100/`
