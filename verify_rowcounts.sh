#!/usr/bin/env bash
# verify_rowcounts.sh - compares COUNT(*) for a list of tables between MySQL and Postgres
set -euo pipefail
source "$(dirname "$0")/config.sh"

TABLES=(customers products orders order_items)  # adjust

echo "Table, MySQL_count, Postgres_count"
for t in "${TABLES[@]}"; do
  MYSQL_COUNT=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" -N -e "SELECT COUNT(*) FROM \`$t\`;" "$MYSQL_DB" 2>/dev/null || echo "ERROR")
  PG_COUNT=$(PGPASSWORD="$PG_PASS" psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -t -c "SELECT COUNT(*) FROM $t;" 2>/dev/null | tr -d '[:space:]' || echo "ERROR")
  echo "$t, $MYSQL_COUNT, $PG_COUNT"
done
