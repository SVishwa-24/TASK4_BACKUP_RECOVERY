#!/usr/bin/env bash
# pg_restore.sh - decrypt and restore PostgreSQL dump
set -euo pipefail
source "$(dirname "$0")/config.sh"

if [ $# -lt 1 ]; then
  echo "Usage: $0 path/to/backup.sql.gz.gpg"
  exit 1
fi
ENC_FILE="$1"
TMP_DIR="/tmp/pg_restore_$(date +%s)"
mkdir -p "$TMP_DIR"

# Decrypt
gpg --output "${TMP_DIR}/dump.sql.gz" --decrypt "$ENC_FILE"

# Uncompress
gunzip "${TMP_DIR}/dump.sql.gz"

# Restore - using psql to run the SQL dump against 'postgres' DB
PGPASSWORD="${PG_PASS}" psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d postgres -f "${TMP_DIR}/dump.sql"

echo "[$(date)] Postgres restore completed." >> "$LOGFILE"
rm -rf "$TMP_DIR"
