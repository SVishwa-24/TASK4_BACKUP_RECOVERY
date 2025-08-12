#!/usr/bin/env bash
# verify_checksum_pg.sh - sample checksum per table (Postgres)
set -euo pipefail
source "$(dirname "$0")/config.sh"

TABLES=(customers products) # pick small tables or sample columns

for t in "${TABLES[@]}"; do
  echo "Checksum for table: $t"
  PGPASSWORD="$PG_PASS" psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -c \            "SELECT md5(string_agg(md5(CAST(row_to_json(t) AS text)), '|' ORDER BY 1)) AS checksum FROM (SELECT * FROM $t) t;"
done
