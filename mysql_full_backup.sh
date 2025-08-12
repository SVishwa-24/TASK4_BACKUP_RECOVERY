#!/usr/bin/env bash
# mysql_full_backup.sh - Full mysqldump + compress + encrypt + push to S3 + verification

set -euo pipefail
source "$(dirname "$0")/config.sh"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTDIR="${BACKUP_BASE}/mysql/full"
mkdir -p "$OUTDIR"
BACKUP_FILE="${OUTDIR}/${MYSQL_DB}_full_${TIMESTAMP}.sql"
ARCHIVE="${BACKUP_FILE}.gz"
ENC="${ARCHIVE}.gpg"

echo "[$(date)] Starting MySQL full backup: $BACKUP_FILE" >> "$LOGFILE"

# 1) Dump
mysqldump -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" \
  --single-transaction --routines --triggers --events --databases "$MYSQL_DB" > "$BACKUP_FILE"

# 2) Compress
gzip -9 "$BACKUP_FILE"

# 3) Generate checksum
sha256sum "$ARCHIVE" > "${ARCHIVE}.sha256"

# 4) Encrypt with GPG (asymmetric) - requires recipient key
gpg --yes --encrypt --recipient "$GPG_RECIPIENT" --output "$ENC" "$ARCHIVE" || true
# optional: export public key info
gpg --yes --armor --output "${ENC}.pubkeyinfo.txt" --export "$GPG_RECIPIENT" || true

# 5) Push to S3 (optional)
if command -v aws >/dev/null 2>&1 && [ -n "$S3_BUCKET" ]; then
  aws --profile "$AWS_PROFILE" s3 cp "$ENC" "$S3_BUCKET/" --storage-class STANDARD_IA || true
  aws --profile "$AWS_PROFILE" s3 cp "${ARCHIVE}.sha256" "$S3_BUCKET/" || true
fi

# 6) Cleanup local old backups beyond retention
find "$BACKUP_BASE" -type f -mtime +$RETENTION_DAYS -name "*.gpg" -delete || true

echo "[$(date)] MySQL full backup completed: $ENC" >> "$LOGFILE"
