#!/usr/bin/env bash
# ─────────────────────────────────────────────
# monitor.sh
# A simple system health monitor for Linux
# Checks CPU, memory, and disk usage against thresholds
# Logs the results and triggers an alert if limits are exceeded
# ─────────────────────────────────────────────

# --- Safety settings ---------------------------------------------------------
# -E : functions inherit ERR trap
# -e : exit immediately if a command exits with a non-zero status
# -u : treat unset variables as errors
# -o pipefail : if any command in a pipeline fails, the whole pipeline fails
set -Eeuo pipefail
IFS=$'\n\t'

# Get project root (so the script works no matter where you call it from)
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]")/.." && pwd)"

#Load helper functions (logging, error traps, etc.)
#shellcheck source=../lib/helpers.sh
source "$ROOT/lib/helpers.sh"

#where to log (default goes into logs/monitor.log inside project folder)
LOG_FILE="${LOG_FILE:-$ROOT/logs/monitor.log)"

#Load optional config file (etx/monitor.env)
#This Lets you customize thres




