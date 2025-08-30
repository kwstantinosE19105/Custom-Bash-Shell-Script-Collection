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
#This Lets you customize thresholds without editing the script
load_env "$ROOT/etc/monitor.env"

# Configuration (with defaults if env file not present)
THRESH_CPU="${THRESH_CPU:-85}"      # max % CPU allowed
THRESH_MEM="${THRESH_MEM:-90}"      # max % memory allowed
THRESH_DISK="${THRESH_DISK:-90}"    # max % disk usage allowed
ALERT_CMD="${ALERT_CMD:-}"          

# Make sure dependencies are available
need awk
need df


# Functions to measure system resource usage
cpu_usage(){
  #Returns current CPU usage as an integer(0-100)
  # Strategy: if `mpstat` exists → use it, else fallback to parsing `top`
  if command -v mpstat >/dev/null 2>&1; then
    #mpstat prints idle %,so we sub
    mpstat 1 1 | awk '/Average/ && $12 ~ /[0-9.]+/ {printf("%.0f\n", 100 - $12)}'
  else
     # fallback: run top twice (first is warm-up), parse "Cpu(s)" line
     top -bn2 | awk '/Cpu\(s\)/ {u=$2+$4} END {printf("%.0f\n", u)}'
  fi

}

mem_usage() {
  # Returns memory usage %
  # Uses /proc/meminfo: (1 - MemAvailable / MemTotal) * 100
  awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END {printf("%.0f\n", (1- a/t)*100)}' /proc/meminfo
}

disk_usage_root() {
  # Returns disk usage % for root partition (/)
  df -P / | awk 'NR==2 {gsub(/%/,"",$5); print $5}'
}

alert() {
  # Logs a warning and runs the alert command if configured
  local msg="$1"
  log WARN "$msg"
  if [[ -n "$ALERT_CMD" ]]; then
    # ALERT_CMD might be something like:
    #   ALERT_CMD='notify-send "ALERT"'
    #   ALERT_CMD='mail -s "Alert" you@example.com'
    eval "$ALERT_CMD" <<< "$msg"
  fi
}

main() {
  # Ensure log directory exists
  mkdir -p "$ROOT/logs"

  #Get usage values
  local c m d
  c="$(cpu_usage)"
  m="$(mem_usage)"
  d="$(disk_usage_root)"

  # Always log the current snapshot
  log INFO "CPU=${c}% MEM=${m}% DISK=${d}%"

   # Compare against thresholds and trigger alerts if exceeded
  (( c > THRESH_CPU ))  && alert "High CPU: ${c}% > ${THRESH_CPU}%"
  (( m > THRESH_MEM ))  && alert "High MEM: ${m}% > ${THRESH_MEM}%"
  (( d > THRESH_DISK )) && alert "Low disk space: ${d}% > ${THRESH_DISK}%"
}

main "$@"





  

  




    
  



