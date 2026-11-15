![CI](https://github.com/Affog7/datapilot/actions/workflows/ci.yml/badge.svg)

# DataPilot

Agent IA qui répond en français à des questions sur une base de données.
Claude écrit le SQL, l'exécute en lecture seule via un serveur MCP, puis affiche
la réponse, la requête, un tableau et un graphique.

> 🚧 Projet en construction (novembre 2026), un livrable par jour.
> Avancement détaillé dans le [journal de bord](JOURNAL.md).

## Stack

- TypeScript strict, monorepo pnpm
- ESLint + Prettier
- API Claude + serveur MCP
- PostgreSQL 16 dans Docker (jeu de données Olist)
- Next.js (interface)

## Structure

```
packages/
  agent/        @datapilot/agent : l'agent (Claude)
  mcp-server/   @datapilot/mcp-server : serveur MCP, accès en lecture seule à la base
apps/
  web/          interface Next.js (à venir)
db/
  init/         scripts lancés au premier démarrage de PostgreSQL
    01-schema.sql        les 9 tables Olist, clés et index
    02-load.sql          chargement des CSV
    03-readonly-role.sh  rôle datapilot_ro (lecture seule)
    04-comments.sql      descriptions des tables et colonnes, lues par l'agent
  data/         CSV Olist (non versionnés, à télécharger)
docker-compose.yml   PostgreSQL 16
tsconfig.base.json   options TypeScript communes, étendues par chaque paquet
```

## Données

[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce),
environ 100 000 commandes réelles (2016-2018), sous licence CC BY-NC-SA 4.0.
Les CSV ne sont pas versionnés : télécharge-les dans `db/data/` avant `docker compose up`.

9 tables, 1,55 M lignes.

| Table                               | Lignes    | Contenu                                          |
| ----------------------------------- | --------- | ------------------------------------------------ |
| `orders`                            | 99 441    | Commandes et dates de chaque étape               |
| `order_items`                       | 112 650   | Articles de chaque commande                      |
| `order_payments`                    | 103 886   | Paiements (une commande peut en avoir plusieurs) |
| `order_reviews`                     | 99 224    | Avis clients (note de 1 à 5, commentaire)        |
| `customers`                         | 99 441    | Clients                                          |
| `sellers`                           | 3 095     | Vendeurs                                         |
| `products`                          | 32 951    | Produits                                         |
| `product_category_name_translation` | 71        | Catégories, du portugais vers l'anglais          |
| `geolocation`                       | 1 000 163 | Coordonnées GPS par code postal                  |

**Piège à connaître :** `customer_id` change à chaque commande. Pour compter les vrais clients, il
faut `customer_unique_id`. « Combien de clients ont passé plus d'une commande ? » donne 0 par
`customer_id`, et 2 997 par `customer_unique_id`.

**Un schéma documenté pour l'agent :**

- Des descriptions dans la base (`COMMENT ON`), lisibles par `datapilot_ro` : ce que signifie
  chaque donnée et le piège à éviter (double comptage, unité, statut d'une vente…). Seules les
  colonnes qui en ont besoin sont décrites.
- Des `CHECK` sur les valeurs autorisées (`order_status`, `payment_type`, `review_score`) : une
  valeur inconnue fait échouer le chargement.
- Des index sur les colonnes de jointure et sur `order_purchase_timestamp` (filtres par période).

## Sécurité : une base en lecture seule

L'application se connecte avec le rôle `datapilot_ro`, protégé par deux barrières :

1. **Le mode de la session** (`default_transaction_read_only = on`) : toute transaction démarre en
   lecture seule. Une écriture échoue avec un message clair :
   `cannot execute UPDATE in a read-only transaction`.
2. **Les droits du rôle** (`GRANT SELECT` uniquement) : même si quelqu'un désactive la barrière 1
   (`SET default_transaction_read_only = off`, que tout utilisateur peut lancer), l'écriture échoue :
   `permission denied for table orders`. Seul un administrateur peut changer ces droits.

En plus : aucune création d'objet (`permission denied for schema public`) et aucune requête de plus
de 5 secondes (`statement_timeout`).

> Si Claude génère un jour un SQL malveillant, par exemple à cause d'une injection de prompt cachée
> dans un avis client, il se heurtera à la deuxième barrière.

## Démarrer en local

Prérequis : Node 22+, pnpm, Docker, une clé API Claude.

1. Installer les dépendances :

   ```bash
   pnpm install
   ```

2. Télécharger les 9 CSV du [jeu de données Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
   et les placer dans `db/data/`.

3. Copier `.env.example` en `.env` et choisir les deux mots de passe :

   ```bash
   POSTGRES_PASSWORD=...       # administrateur postgres
   DATAPILOT_RO_PASSWORD=...   # rôle applicatif datapilot_ro
   ```

4. Démarrer PostgreSQL. Au premier démarrage, les scripts de `db/init/` créent le schéma,
   chargent les CSV et créent le rôle `datapilot_ro` :

   ```bash
   docker compose up -d
   docker logs datapilot-db   # une ligne « COPY <n> » par table, puis « Rôle datapilot_ro créé »
   ```

   Les scripts ne tournent que sur un volume vide. Pour tout reconstruire :
   `docker compose down -v` puis `docker compose up -d`.

5. Vérifier les deux barrières avec le rôle applicatif :

   ```bash
   docker exec -it datapilot-db psql -U datapilot_ro -d olist
   ```

   ```sql
   SELECT count(*) FROM orders;                    -- 99441
   UPDATE orders SET order_status = 'x';           -- barrière 1 : read-only transaction
   SET default_transaction_read_only = off;
   UPDATE orders SET order_status = 'x';           -- barrière 2 : permission denied
   SELECT pg_sleep(10);                            -- coupée au bout de 5 s
   ```

## Scripts

| Commande            | Rôle                                                  |
| ------------------- | ----------------------------------------------------- |
| `pnpm typecheck`    | Vérifie les types de tous les paquets (sans compiler) |
| `pnpm build`        | Compile chaque paquet de `src/` vers `dist/`          |
| `pnpm lint`         | Analyse le code avec ESLint                           |
| `pnpm format`       | Formate le code avec Prettier                         |
| `pnpm format:check` | Vérifie le formatage sans rien modifier               |

(Les étapes complètes arrivent au fil du projet.)

## Auteur

Augustin Affognon — développeur full-stack & IA
