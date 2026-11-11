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