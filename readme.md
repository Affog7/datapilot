# DataPilot

Agent IA qui répond en français à des questions sur une base de données.
Claude écrit le SQL, l'exécute en lecture seule via un serveur MCP, puis affiche
la réponse, la requête, un tableau et un graphique.

> 🚧 Projet en construction (novembre 2026), un livrable par jour.

## Stack

- TypeScript, monorepo pnpm
- API Claude + serveur MCP
- PostgreSQL 16 (jeu de données Pagila)
- Next.js (interface)

## Démarrer en local

Prérequis : Node 22+, pnpm, Docker, une clé API Claude.

​```bash
pnpm install
​```

(Les étapes complètes arrivent au fil du projet.)

## Auteur

Augustin Affognon — développeur full-stack & IA