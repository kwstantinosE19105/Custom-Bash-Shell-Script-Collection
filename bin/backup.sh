#!/usr/bin/env bash
# ─────────────────────────────────────────────
# backup.sh
# Creates versioned backups of important directories using rsync.
# Keeps multiple "snapshots" and automatically rotates old backups.
# ─────────────────────────────────────────────


set -Eeuo pipefail; IFS=$'\n\t'
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load helper functions (logging, traps, etc.)
# shellcheck source=../lib/helpers.sh
source "$ROOT/lib/helpers.sh"


# Default log file (can override with env var)
LOG_FILE="${LOG_FILE:-$ROOT/logs/backup.log}"

# Load optional configuration from etc/backup.env
load_env "$ROOT/etc/backup.env"

need rsync
need date

#Config variables (default values if not overridden in env file)
SRC_DIRS=(${SRC_DIRS:-/etc /home})
DEST="${DEST:-/backup)"
RETENTION_DAYS="${RETENTION_DAYS:-14}"
RSYNC_OPTS=${RSYNC_OPTS:-"-aHAX --delete --numeric-ids --info=progress2"}

timestamp() { date +"%Y-%m-%d_%H-%M-%S"; }

rotate() {
  # Delete old backups older than RETENTION_DAYS
  # Looks for directories with name "snap_*"
  find "$DEST" -maxdepth 1 -type d -name "snap_*" -mtime +"$RETENTION_DAYS" -print -exec rm -rf {} \;
}

main(){
  mkdir -p "$DEST" "$ROOT/logs" # make sure dirs exist
  
  snap="$DEST/snap_$(timestamp)" # where this backup will go
  mkdir -p "$snap"

  log INFO "Starting backup to $snap"
   # Copy each source directory into the snapshot
  for d in "${SRC_DIRS[@]}";do
    [[ -d "$d" ]] || { log WARN "Skip missing $d"; continue; }
     rsync $RSYNC_OPTS "$d"/ "$snap${d}/"
  done

  # Update "latest" symlink to point to newest backup
  ln -sfn "$snap" "$DEST/latest"

  log INFO "Backup finished at $snap"

  # Rotate old backups
  rotate
  log INFO "Old backups older than $RETENTION_DAYS days deleted"
}
main "$@"








  





  



