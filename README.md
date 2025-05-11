# Application Drupal d'Analyse de Comptes Bancaires

Ce projet met en place un environnement de développement pour une application Drupal destinée à l'analyse de comptes bancaires. L'environnement utilise Docker Compose, Traefik comme reverse proxy, et Portainer pour la gestion des conteneurs Docker.

## Prérequis

- Docker (dernière version recommandée)
- Docker Compose (dernière version recommandée)
- Un éditeur de texte ou IDE
- Avoir modifié votre fichier `/etc/hosts` (ou équivalent sur votre système) pour faire pointer les domaines suivants vers `127.0.0.1`:
  - `drupal.bank.localhost`
  - `portainer.bank.localhost`
  - `traefik.bank.localhost`

## Structure des services

- `traefik`: Reverse proxy pour router les requêtes HTTP/HTTPS vers les services appropriés. Dashboard accessible sur `http://traefik.bank.localhost`.
- `portainer`: Interface de gestion pour Docker. Accessible sur `http://portainer.bank.localhost`.
- `db`: Service de base de données PostgreSQL pour Drupal.
- `drupal`: L'application Drupal elle-même. Accessible sur `http://drupal.bank.localhost`.

## Configuration

1.  **Fichier d'environnement**: Copiez ou renommez `.env.example` en `.env` si vous souhaitez personnaliser les variables (par défaut, le fichier `.env` fourni devrait fonctionner pour un démarrage rapide).
    Modifiez les variables dans `.env` selon vos besoins, notamment `APP_DOMAIN`, `DB_NAME`, `DB_USER`, et `DB_PASSWORD`.

2.  **Fichier hosts**: Assurez-vous que votre fichier `/etc/hosts` (ou l'équivalent pour Windows/macOS) contient les lignes suivantes pour que les domaines locaux fonctionnent :
    ```
    127.0.0.1 drupal.bank.localhost
    127.0.0.1 portainer.bank.localhost
    127.0.0.1 traefik.bank.localhost
    ```

## Démarrage de l'environnement

Pour lancer l'ensemble des services, exécutez la commande suivante à la racine du projet :

```bash
docker-compose up -d
```

Cela va construire les images si nécessaire, créer les conteneurs, les réseaux et les volumes, puis démarrer les services en arrière-plan (`-d`).

## Accès aux services

-   **Application Drupal**: [http://drupal.bank.localhost](http://drupal.bank.localhost)
    -   Lors du premier accès, vous devrez suivre l'assistant d'installation de Drupal.
-   **Dashboard Traefik**: [http://traefik.bank.localhost](http://traefik.bank.localhost)
-   **Portainer**: [http://portainer.bank.localhost](http://portainer.bank.localhost)
    -   Lors du premier accès à Portainer, vous devrez créer un compte administrateur.

## Volumes Docker

Les données persistantes et le code custom sont stockés dans des volumes Docker nommés :

-   `db_data`: Données de PostgreSQL.
-   `portainer_data`: Données de Portainer.
-   `drupal_modules`: Modules Drupal custom (`/var/www/html/modules/custom`).
-   `drupal_profiles`: Profils Drupal custom (`/var/www/html/profiles/custom`).
-   `drupal_sites`: Configuration des sites Drupal (`/var/www/html/sites`). C'est ici que se trouvera `settings.php` et le répertoire `files`.
-   `drupal_themes`: Thèmes Drupal custom (`/var/www/html/themes/custom`).

Vous pouvez inspecter ces volumes avec `docker volume ls` et `docker volume inspect <nom_du_volume>`.

## Commandes utiles

-   **Voir les logs des services**:
    ```bash
    docker-compose logs -f <nom_du_service> # Par exemple, docker-compose logs -f drupal
    ```
-   **Arrêter les services**:
    ```bash
    docker-compose down
    ```
-   **Arrêter et supprimer les volumes (ATTENTION: supprime les données !)**:
    ```bash
    docker-compose down -v
    ```
-   **Exécuter Drush dans le conteneur Drupal**:
    ```bash
    docker-compose exec drupal drush <commande_drush>
    # Par exemple, pour vider les caches:
    # docker-compose exec drupal drush cr
    ```
-   **Accéder au shell du conteneur Drupal**:
    ```bash
    docker-compose exec drupal bash
    ```

## Prochaines étapes

1.  Lancer l'environnement avec `docker-compose up -d`.
2.  Configurer Drupal via son interface web.
3.  Commencer le développement de vos modules et thèmes custom.
