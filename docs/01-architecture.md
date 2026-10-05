
---

## Phase 4 — Sessions utilisateur et MAJ sans interruption

### Comparatif des solutions de session

| Solution | Avantages | Inconvénients | Impact dispo |
|---|---|---|---|
| **(a) Sticky sessions** | Simple, aucune modif applicative | Perte de session si serveur tombe | Bonne tant que le serveur reste up |
| **(b) Session partagée (Redis)** | Persistante, répartition équilibrée | Nouveau SPOF, complexité | Meilleure à terme |
| **(c) JWT** | Aucun stockage serveur | Refonte appli, révocation complexe | Excellente mais lourde |

**Choix retenu : (a) Sticky sessions par cookie HAProxy.**

**Justification :** implémentation rapide (une directive `cookie`), aucune modification de l'application PHP. Compromis assumé : perte de session en cas de bascule — acceptable pour un portail de RDV où l'utilisateur peut se reconnecter.

**Limite assumée :** en production, la solution (b) avec Redis serait préférable pour une vraie persistance. C'est l'extension E4 du sujet.

### Q1 — Patch management et HA

Les 6 étapes du patch management (slide 12) : Recenser, Évaluer, Tester, Déployer, Vérifier, Documenter.

**La HA rend possible l'étape 4 (Déployer) sans coupure de service.** Sans HA, chaque déploiement = interruption. Avec HA + drain, on met à jour un serveur pendant que l'autre sert.

**L'étape 3 (Tester) reste entièrement à notre charge.** La HA ne teste pas la nouvelle version à notre place. Si la 1.1 est défectueuse, la HA propage le bug aux deux serveurs — c'est pour ça qu'un déploiement canari est préférable.

### Q2 — Sonde base de données

Une sonde qui interroge la BDD toutes les 2 s avec 2 répartiteurs = **4 requêtes/seconde en permanence**. Si la base est déjà saturée, ça aggrave la charge. **La sonde peut faire tomber la base qu'elle surveille.**

**Solution :** sonde TCP légère sur le port, ou espacer les sondes (10 s au lieu de 2 s).

### Q3 — Rollback

Si la 1.1 est défectueuse après avoir traité les deux serveurs, plus de rollback possible sans interruption.

**Solution à prévoir (slide 13) :** **déploiement canari** — un serveur d'abord, surveiller, puis l'autre. Si problème, rollback le premier sans impact sur le second.
