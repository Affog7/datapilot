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
- PostgreSQL 16 (jeu de données Pagila)
- Next.js (interface)

## Structure

```
packages/
  agent/        @datapilot/agent : l'agent (Claude)
  mcp-server/   @datapilot/mcp-server : serveur MCP, accès en lecture seule à la base
apps/
  web/          interface Next.js (à venir)
tsconfig.base.json   options TypeScript communes, étendues par chaque paquet
```

## Démarrer en local

Prérequis : Node 22+, pnpm, Docker, une clé API Claude.

```bash
pnpm install
```

## Scripts

| Commande            | Rôle                                                     |
| ------------------- | -------------------------------------------------------- |
| `pnpm typecheck`    | Vérifie les types de tous les paquets (sans compiler)    |
| `pnpm build`        | Compile chaque paquet de `src/` vers `dist/`             |
| `pnpm lint`         | Analyse le code avec ESLint                              |
| `pnpm format`       | Formate le code avec Prettier                            |
| `pnpm format:check` | Vérifie le formatage sans rien modifier                  |

(Les étapes complètes arrivent au fil du projet.)

## Auteur

Augustin Affognon — développeur full-stack & IA
