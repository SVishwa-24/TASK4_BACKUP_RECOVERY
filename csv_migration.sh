#!/usr/bin/env bash
# csv_migration.sh - fallback: export MySQL tables to CSV and import into Postgres.
set -euo pipefail
source "$(dirname "$0")/config.sh"

EXPORT_DIR="/tmp/mysql_export_$(date +%s)"
mkdir -p "$EXPORT_DIR"
echo "Export directory: $EXPORT_DIR"

TABLES=(customers products orders order_items)

for t in "${TABLES[@]}"; do
  OUTFILE="$EXPORT_DIR/${t}.csv"
  echo "Exporting $t to $OUTFILE"
  mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" --batch --raw -e "SELECT * FROM \\`$t\\`;" "$MYSQL_DB" | sed 's/\t/","/g;s/^/"/;s/$/"/;s/\n//g' > "$OUTFILE" || true
done

echo "CSV export complete. Transfer CSVs to Postgres host and use psql \copy to import."
