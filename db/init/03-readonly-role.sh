#!/usr/bin/env bash
# Crée le rôle applicatif datapilot_ro : il ne peut QUE lire.
set -euo pipefail

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
  -v ro_password="$DATAPILOT_RO_PASSWORD" <<-'EOSQL'
  -- Le compte utilisé par l'application. :'ro_password' insère la variable psql
  -- entre guillemets, sans que le mot de passe soit écrit dans le fichier.
  CREATE ROLE datapilot_ro LOGIN PASSWORD :'ro_password';

  -- Les droits minimum pour lire : se connecter, voir le schéma, lire les tables.
  GRANT CONNECT ON DATABASE olist TO datapilot_ro;
  GRANT USAGE ON SCHEMA public TO datapilot_ro;
  GRANT SELECT ON ALL TABLES IN SCHEMA public TO datapilot_ro;

  -- Les tables créées plus tard seront lisibles aussi (sinon il faudrait refaire le GRANT).
  ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO datapilot_ro;

  -- Barrière 1 : toute transaction de ce rôle démarre en lecture seule.
  ALTER ROLE datapilot_ro SET default_transaction_read_only = on;

  -- Garde-fou : aucune requête ne peut tourner plus de 5 secondes.
  ALTER ROLE datapilot_ro SET statement_timeout = '5s';
EOSQL

echo "Rôle datapilot_ro créé (lecture seule, timeout 5 s)."