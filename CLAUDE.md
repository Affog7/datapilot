# CLAUDE.md — DataPilot

## Le projet

DataPilot est un agent IA qui répond en français à des questions posées en langage naturel : Claude
écrit le SQL, l'exécute en lecture seule via un serveur MCP, puis renvoie la réponse, la requête,
un tableau et un graphique. Les données sont le jeu public **Olist** (e-commerce brésilien,
~100 000 commandes 2016-2018, 9 tables, 1,55 M lignes) chargé dans PostgreSQL 16.

## Architecture

Monorepo pnpm (`apps/*`, `packages/*`).

- `packages/agent/` — `@datapilot/agent` : l'agent Claude (SDK `@anthropic-ai/sdk`) ; `src/env.ts`
  charge le `.env` racine (`requireEnv`), `src/hello.ts` est le premier appel à l'API.
- `packages/mcp-server/` — `@datapilot/mcp-server` : serveur MCP qui donnera à l'agent l'accès en
  lecture seule à la base (outils prévus : exécution de SQL, `describe_table`) ; squelette pour l'instant.
- `apps/web/` — interface Next.js (à venir, dossier vide).
- `db/init/` — scripts lancés par PostgreSQL au premier démarrage, dans l'ordre : `01-schema.sql`
  (tables, clés, index, `CHECK`), `02-load.sql` (`COPY` des CSV), `03-readonly-role.sh` (rôle
  `datapilot_ro`), `04-comments.sql` (`COMMENT ON` lus par l'agent).
- `db/data/` — les 9 CSV Olist, **non versionnés**, montés en lecture seule dans `/data` du conteneur.
- Racine : `docker-compose.yml` (PostgreSQL 16), `tsconfig.base.json` (options TS communes, étendues
  par chaque paquet), `JOURNAL.md` (rétro quotidienne), `.env.example` (variables attendues).

## Commandes

```bash
pnpm install            # installe les dépendances de tout le monorepo
pnpm typecheck          # vérifie les types de tous les paquets, sans compiler
pnpm build              # compile chaque paquet de src/ vers dist/
pnpm lint               # analyse le code avec ESLint
pnpm format             # formate tout le code avec Prettier
pnpm format:check       # vérifie le formatage sans rien modifier
pnpm hello              # lance packages/agent/src/hello.ts (appel de test à l'API Claude)

docker compose up -d                       # démarre PostgreSQL (init auto si le volume est vide)
docker logs datapilot-db                   # vérifie l'init : une ligne « COPY <n> » par table, puis « Rôle datapilot_ro créé »
docker compose down -v                     # arrête et SUPPRIME le volume pgdata (la prochaine init rejoue tout db/init/)
docker exec -it datapilot-db psql -U datapilot_ro -d olist   # console SQL avec le rôle applicatif
docker exec datapilot-db psql -U postgres -d olist -f /docker-entrypoint-initdb.d/04-comments.sql
                                           # rejoue les commentaires du schéma sans reconstruire la base
```

- Les scripts de `db/init/` ne tournent **que sur un volume vide** : après une modification du
  schéma, du chargement ou du rôle, il faut `docker compose down -v` puis `docker compose up -d`.
- Pas encore de tests : `pnpm test` échoue volontairement. Avant un commit, lancer
  `pnpm typecheck`, `pnpm lint` et `pnpm format:check`.

## Règles de sécurité — non négociables

- **L'application se connecte uniquement avec `datapilot_ro`**, jamais avec `postgres`. Le compte
  `postgres` sert à l'administration (init, `COMMENT ON`), pas au code.
- **Deux barrières, toujours les deux** :
  1. le mode de session `default_transaction_read_only = on` (message clair en cas d'écriture,
     mais contournable par `SET ... = off`) ;
  2. les droits du rôle : `GRANT SELECT` uniquement (tient même si la barrière 1 est contournée).
     Ne jamais donner à `datapilot_ro` un droit d'écriture ou de création, ni désactiver la
     barrière 1 dans le code. Garde-fou en plus : `statement_timeout = 5s`.
- **Le SQL généré par Claude n'est pas fiable** (injection de prompt possible, par exemple dans un
  avis client) : la sécurité repose sur la base, jamais sur le prompt ni sur un filtrage du SQL.
- **Aucun secret dans Git** : `.env` et `db/data/` sont ignorés. Toute nouvelle variable va dans
  `.env.example` avec une valeur factice. Les mots de passe passent par des variables
  (`:'ro_password'` dans psql, `requireEnv` en TS), jamais en dur. Relire `git status` avant
  chaque commit.

## Conventions

- **TypeScript strict** (`strict`, `noUncheckedIndexedAccess`, cible ES2023) et **ESM**
  (`"type": "module"`, modules `NodeNext`).
- **Imports relatifs avec l'extension `.js`**, même depuis un fichier `.ts` :
  `import { requireEnv } from "./env.js";`.
- **Commentaires, messages d'erreur et logs en français.**
- **Conventional Commits** en français : `feat: …`, `fix: …`, `docs: …`, `chore: …`.
- **Montants en `NUMERIC(10,2)`** (réals brésiliens, BRL), jamais `REAL` / `DOUBLE PRECISION`.
- **Haiku 5.5 en dev** : le modèle vient de `ANTHROPIC_MODEL` (`claude-haiku-5-5` dans
  `.env.example`), jamais codé en dur. Garder un `max_tokens` large (la réflexion compte dedans).
- Prettier : lignes de 100 caractères. `.sh` et `.yml` en fins de ligne LF (`.gitattributes`),
  sinon les scripts plantent dans le conteneur Linux.
- Schéma : chaque table reprend les colonnes de son CSV **dans le même ordre** (`COPY` sans liste
  de colonnes) ; les fautes d'origine (`product_name_lenght`) sont conservées ; les codes postaux
  sont en texte (zéros initiaux).
- Piège à transmettre à l'agent : `customer_id` change à chaque commande ; pour compter des
  personnes, utiliser `customer_unique_id`. Une vente réalisée = `order_status = 'delivered'`.
