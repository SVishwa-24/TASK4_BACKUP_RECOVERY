#!/usr/bin/env bash
# mysql_binlog_backup.sh - copy mysql binlogs for incremental recovery
set -euo pipefail
source "$(dirname "$0")/config.sh"

BINLOG_DIR="/var/lib/mysql"   # adjust to your MySQL binlog dir
OUTDIR="${BACKUP_BASE}/mysql/binlogs/$(date +%Y%m%d)"
mkdir -p "$OUTDIR"

# Copy current binlogs (requires read permission)
rsync -av --relative "${BINLOG_DIR}/mysql-bin.*" "$OUTDIR/" || true

# Optionally gzip and encrypt each
for f in "$OUTDIR"/mysql-bin.*; do
  [ -f "$f" ] || continue
  gzip -9 "$f"
  gpg --yes --encrypt --recipient "$GPG_RECIPIENT" --output "${f}.gz.gpg" "${f}.gz" || true
  rm -f "${f}.gz" || true
done

# Push to S3 if configured
if command -v aws >/dev/null 2>&1 && [ -n "$S3_BUCKET" ]; then
  aws --profile "$AWS_PROFILE" s3 sync "$OUTDIR" "$S3_BUCKET/mysql/binlogs/$(date +%Y%m%d)/" || true
fi

echo "[$(date)] MySQL binlog backup complete." >> "$LOGFILE"
