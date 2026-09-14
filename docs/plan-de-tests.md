# Plan de tests

1. **Disponibilité nominale**: requêtes HTTP continues vers `192.168.10.100`
2. **Panne LB actif**: arrêt Keepalived/HAProxy sur LB1, attente bascule LB2
3. **Panne WEB1**: arrêt nginx/php-fpm sur WEB1, vérification continuité via WEB2
4. **Retour nominal**: redémarrage des services et vérification de l'état cluster
5. **Mesures**: calcul RTO/RPO, taux de disponibilité, latence moyenne
