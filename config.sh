# config.sh - edit this file with your environment specific values
# MySQL
MYSQL_HOST="mysql_host"
MYSQL_PORT=3306
MYSQL_USER="mysql_user"
MYSQL_PASS="mysql_password"
MYSQL_DB="my_database"

# PostgreSQL
PG_HOST="pg_host"
PG_PORT=5432
PG_USER="pg_user"
PG_PASS="pg_password"
PG_DB="my_database"

# General
BACKUP_BASE="/var/backups/db_backups"   # local backup directory
RETENTION_DAYS=30                       # keep backups for 30 days
GPG_RECIPIENT="backup@yourdomain.com"   # or use GPG key id
S3_BUCKET="s3://your-backup-bucket/path" # optional S3 bucket
AWS_PROFILE="default"                   # optional aws profile name

# Logging
LOGFILE="/var/log/db_backup.log"
mkdir -p "$BACKUP_BASE"
