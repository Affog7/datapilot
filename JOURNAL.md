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