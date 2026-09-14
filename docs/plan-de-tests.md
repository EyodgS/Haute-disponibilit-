# Plan de tests — Haute Disponibilité

## Scénario 1 : disponibilité nominale

- Vérifier `/`, `/health`, `/appointments`
- Résultat attendu : HTTP 200

## Scénario 2 : panne d’un nœud applicatif

- Stopper `app1`
- Tester `http://localhost:8080/`
- Résultat attendu : service toujours disponible via `app2`

## Scénario 3 : reprise nœud applicatif

- Redémarrer `app1`
- Vérifier les logs et l’état healthy
- Résultat attendu : retour à la redondance nominale

## Scénario 4 : indisponibilité base de données

- Stopper `db`
- Tester `/health`
- Résultat attendu : code 503 (mode dégradé détecté)

## Scénario 5 : restauration données

- Exécuter une sauvegarde
- Simuler perte de données contrôlée
- Restaurer puis vérifier cohérence des rendez-vous
