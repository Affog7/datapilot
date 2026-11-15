# Journal de bord — DataPilot

Une courte rétro par jour : ce qui a marché, ce qui a coincé, ce que je change.

## Jour 1 — mercredi 11 novembre : installation et monorepo

**Livré**

- Environnement prêt : Node 26, pnpm 12, Git, Docker.
- Monorepo pnpm avec deux paquets : `@datapilot/agent` et `@datapilot/mcp-server`.
- Dépôt GitHub public, premier README.

**Ce qui a coincé, et comment je l'ai résolu**

- Node 20 trop ancien : son corepack ne reconnaissait plus la clé de signature de pnpm.
  → Mise à jour vers Node 26.
- `corepack enable` a laissé des raccourcis `pnpm` cassés dans `C:\Program Files\nodejs`
  (Node 26 n'inclut plus corepack). → Suppression des raccourcis, pnpm réinstallé via npm.
- `git init` lancé depuis un terminal administrateur : Git refusait le dépôt
  (« dubious ownership »). → Dépôt recréé depuis un terminal normal.

**Ce que je retiens**

- Le terminal administrateur ne sert qu'aux installations, jamais au projet.
- Toujours lire la dernière ligne d'une erreur : elle donnait la version de Node en cause.

**Demain**

- Étape 2 : TypeScript strict, ESLint, Prettier.
- Étape 3 : PostgreSQL + Pagila + rôle lecture seule.

## Jour 2 — jeudi 12 novembre : TypeScript strict, ESLint, Prettier

**Livré**

- `tsconfig.base.json` commun : `strict`, `noUncheckedIndexedAccess`, modules `NodeNext`,
  cible ES2023. Chaque paquet l'étend et compile `src/` vers `dist/`.
- Un premier `src/index.ts` dans `agent` et `mcp-server`, `main` pointé sur `dist/index.js`.
- ESLint (config « flat ») : règles recommandées JS + typescript-eslint, et
  `eslint-config-prettier` pour couper les règles qui entrent en conflit avec Prettier.
- Prettier : lignes de 100 caractères, `dist`, `node_modules` et `pnpm-lock.yaml` ignorés.
- Scripts racine : `lint`, `format`, `format:check`, plus `typecheck` et `build` lancés dans
  chaque paquet via `pnpm -r`.

**À régler avant de continuer**

- Le bloc `devDependencies` a disparu du `package.json` racine (fichier réécrit après le
  `pnpm add -D`). Au lancement d'un script, pnpm a resynchronisé `node_modules` sur ce
  `package.json` et désinstallé TypeScript, ESLint et Prettier : `pnpm lint` répond
  « 'eslint' n'est pas reconnu… ». → Relancer
  `pnpm add -D typescript @types/node eslint @eslint/js typescript-eslint eslint-config-prettier prettier`.
- TypeScript 7 est installé, mais typescript-eslint 8.72 n'accepte officiellement que
  TypeScript < 6.1. → À vérifier au premier `pnpm lint` ; sinon, revenir à TypeScript 6.0.

**Ce que je retiens**

- Une config TypeScript de base partagée évite de recopier les mêmes options dans chaque paquet.
- Après un `pnpm add`, ne plus réécrire `package.json` à la main sans relire le `git diff`.

**Demain**

- Remettre les outils en place et faire passer `typecheck`, `lint` et `format:check`.
- Étape 3 : PostgreSQL + Pagila + rôle lecture seule.

## Jour 3 — samedi 14 et dimanche 15 novembre : PostgreSQL, Olist et rôle lecture seule

**Livré**

- Reliquat du jour 2 : `devDependencies` remises dans `package.json`, TypeScript ramené à 6.0
  (`~6.0.3`) pour rester compatible avec typescript-eslint.
- PostgreSQL 16 dans Docker (`docker-compose.yml`), avec le jeu de données **Olist**
  (e-commerce brésilien, ~100 000 commandes, 9 tables) à la place de Pagila.
- Trois scripts dans `db/init/`, lancés automatiquement au premier démarrage :
  - `01-schema.sql` : les 9 tables, clés primaires, clés étrangères et index de jointure ;
  - `02-load.sql` : `COPY` des 9 CSV, soit 1,55 M lignes (dont 1 M pour `geolocation`) ;
  - `03-readonly-role.sh` : le rôle `datapilot_ro`, qui ne peut que lire.
- Mots de passe dans `.env` (non versionné) : `docker compose` refuse de démarrer s'il en manque un.
- `.gitattributes` : fins de ligne LF forcées pour `.sh` et `.yml`. En CRLF (clone Windows),
  le script bash planterait dans le conteneur Linux.
- Init complète vérifiée sur une base vide (`docker compose down -v` puis `up -d`) : les trois
  scripts passent sans intervention manuelle.

**Les deux barrières du rôle `datapilot_ro`**

| Test                                      | Résultat                                           | Ce que ça prouve                                   |
| ----------------------------------------- | -------------------------------------------------- | -------------------------------------------------- |
| `SELECT count(*)`                         | 99 441                                             | La lecture fonctionne                              |
| 1er `UPDATE`                              | `cannot execute UPDATE in a read-only transaction` | Barrière 1 : la transaction est en lecture seule   |
| `SET default_transaction_read_only = off` | `SET`                                              | N'importe qui peut désactiver la barrière 1…       |
| 2e `UPDATE`                               | `permission denied for table orders`               | …mais la barrière 2 tient : aucun droit d'écriture |
| `CREATE TABLE`                            | `permission denied for schema public`              | Impossible de créer des objets                     |
| `pg_sleep(10)`                            | `canceling statement due to statement timeout`     | Une requête trop longue est coupée au bout de 5 s  |

Le premier refus vient du **mode** de la session (`default_transaction_read_only`), que
l'utilisateur peut changer lui-même. Le second vient des **droits** du rôle (`GRANT`), que seul un
administrateur peut changer. La barrière 1 arrête les erreurs simples avec un message clair ; la
barrière 2 tient même face à quelqu'un qui contourne la première.

**Ce qui a coincé, et comment je l'ai résolu**

- Le piège `customer_unique_id` : `customer_id` change à chaque commande. « Combien de clients
  ont passé plus d'une commande ? » donne **0** en comptant par `customer_id`, et **2 997** par
  `customer_unique_id` (96 096 vraies personnes pour 99 441 `customer_id`).
  → Commentaire dans le schéma et index sur `customer_unique_id`.
- Le « script vide », en trois versions :
  - `03-readonly-role.sh` enregistré vide : l'init passe sans erreur, mais `datapilot_ro`
    n'existe pas et la connexion est refusée ;
  - `02-load.sql` vide : les tables existent, mais ne contiennent aucune ligne ;
  - scripts corrigés mais jamais relancés : `/docker-entrypoint-initdb.d` ne s'exécute que sur
    un volume `pgdata` vide.
    → `docker compose down -v` puis `docker compose up -d`, et lecture de `docker logs datapilot-db` :
    une ligne `COPY <n>` par table, puis « Rôle datapilot_ro créé ».
- `db/init/` était dans le `.gitignore` : le commit du 14 ne contenait pas les scripts, et le
  schéma était invisible sur GitHub. → Ligne retirée ; `git status` montre les scripts et
  `.gitattributes`, et aucun `.csv` ni `.env`.

**Ce que je retiens**

- Un script vide « réussit » : l'absence d'erreur ne prouve rien. Je vérifie le résultat
  (logs, `count(*)`).
- Lire les CSV avant d'écrire le schéma : `review_id` non unique (814 doublons), codes postaux à
  zéros initiaux (donc en texte), 2 catégories absentes de la table de traduction.
- La lecture seule repose sur deux barrières : le mode de session et les droits. Une seule ne
  suffit pas.
- Le piège `customer_unique_id` devra figurer dans la description du schéma donnée à Claude.
- Relire `git status` avant chaque commit : ce qui est ignoré n'est pas poussé.

**Demain**

- Étape 4 : premier appel à l'API Claude, après la section « Accessing Claude with the API »
  du cours Anthropic Academy.
