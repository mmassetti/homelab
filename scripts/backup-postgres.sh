#!/bin/bash
# Dumps every Postgres container (all databases + roles via pg_dumpall) to the NAS.
# Cron: 0 8 * * * (UTC) — see host crontab. Retention: 14 days, pruned each run.
set -uo pipefail

DEST=/mnt/nas/Backups/postgres
DATE=$(date +%Y%m%d)
CONTAINERS=(ricota-db-db-1 media_tracker_db jellystat-db)

mkdir -p "$DEST"

status=0
for c in "${CONTAINERS[@]}"; do
    out="$DEST/${c}-${DATE}.sql.gz"
    if docker exec "$c" pg_dumpall -U postgres 2>"/tmp/backup-postgres-${c}.err" | gzip > "$out"; then
        echo "$(date -Iseconds) OK ${c} -> ${out} ($(du -h "$out" | cut -f1))"
    else
        echo "$(date -Iseconds) FAILED ${c} — see /tmp/backup-postgres-${c}.err"
        status=1
    fi
done

find "$DEST" -name "*.sql.gz" -mtime +14 -delete

exit $status
