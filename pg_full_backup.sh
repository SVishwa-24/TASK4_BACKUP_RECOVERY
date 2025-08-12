#!/usr/bin/env bash
# pg_full_backup.sh - Full pg_dump of a single DB + compress + encrypt + push to S3

set -euo pipefail
source "$(dirname "$0")/config.sh"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTDIR="${BACKUP_BASE}/postgres/full"
mkdir -p "$OUTDIR"
BACKUP_FILE="${OUTDIR}/${PG_DB}_full_${TIMESTAMP}.sql"
ARCHIVE="${BACKUP_FILE}.gz"
ENC="${ARCHIVE}.gpg"

echo "[$(date)] Starting PostgreSQL full backup: $BACKUP_FILE" >> "$LOGFILE"

# Use pg_dump for a single DB (schema + data)
PGPASSWORD="${PG_PASS}" pg_dump -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -F p -d "$PG_DB" -v -f "$BACKUP_FILE"

# Compress
gzip -9 "$BACKUP_FILE"

# Checksum
sha256sum "$ARCHIVE" > "${ARCHIVE}.sha256"

# Encrypt
gpg --yes --encrypt --recipient "$GPG_RECIPIENT" --output "$ENC" "$ARCHIVE" || true

# Push to S3
if command -v aws >/dev/null 2>&1 && [ -n "$S3_BUCKET" ]; then
  aws --profile "$AWS_PROFILE" s3 cp "$ENC" "$S3_BUCKET/" || true
  aws --profile "$AWS_PROFILE" s3 cp "${ARCHIVE}.sha256" "$S3_BUCKET/" || true
fi

# Cleanup old
find "$BACKUP_BASE" -type f -mtime +$RETENTION_DAYS -name "*.gpg" -delete || true

echo "[$(date)] Postgres full backup completed: $ENC" >> "$LOGFILE"
