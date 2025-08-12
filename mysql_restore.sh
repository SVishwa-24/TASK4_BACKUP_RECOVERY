#!/usr/bin/env bash
# mysql_restore.sh - decrypt and restore a MySQL full backup file
set -euo pipefail
source "$(dirname "$0")/config.sh"

if [ $# -lt 1 ]; then
  echo "Usage: $0 path/to/backup.sql.gz.gpg"
  exit 1
fi
ENC_FILE="$1"
TMP_DIR="/tmp/mysql_restore_$(date +%s)"
mkdir -p "$TMP_DIR"

# 1) Decrypt
gpg --output "${TMP_DIR}/dump.sql.gz" --decrypt "$ENC_FILE"

# 2) Uncompress
gunzip "${TMP_DIR}/dump.sql.gz"

# 3) Restore (this will overwrite data)
mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" < "${TMP_DIR}/dump.sql"

echo "[$(date)] MySQL restore completed." >> "$LOGFILE"
rm -rf "$TMP_DIR"
