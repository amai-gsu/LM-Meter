#!/usr/bin/env bash

set -euo pipefail

# ───────────────────────────────────
# Config / environment defaults
# ───────────────────────────────────
ADB_RUNNER=${ADB_RUNNER:-adb}

# first connected device if DEVICE_ID not preset
DEVICE_ID=${DEVICE_ID:-$($ADB_RUNNER devices | grep -v List | cut -f1 | head -n1)}

LOGFILE_ROOT=${LOGFILE_ROOT:-"/data/local/tmp"}          # where logcat dumps on device
OUTFILE_ROOT=${OUTFILE_ROOT:-"$HOME/mobileLLM/Neurips25/test/logcat"}

TRACE_DEVICE_DIR=${TRACE_DEVICE_DIR:-"/sdcard/Download"} # where LogitProcessor writes traces
TRACE_PATTERN="trace_*.json"

NOW=$(date +"%Y%m%d%H%M%S")
OUTDIR="${OUTFILE_ROOT}/${NOW}"
mkdir -p "${OUTDIR}"

# ───────────────────────────────────
# 1) Capture logcat → device temp
# ───────────────────────────────────
echo "=== Capturing logs on device (${LOGFILE_ROOT}) ==="
LOG_TMP_DEV="${LOGFILE_ROOT}/logcat_${NOW}.mlc.log"
$ADB_RUNNER -s "$DEVICE_ID" logcat -f "$LOG_TMP_DEV" -d -v raw "TVM_RUNTIME:I" "*:S"

# ───────────────────────────────────
# 2) Pull logcat to host
# ───────────────────────────────────
echo "=== Pulling logcat to host (${OUTDIR}) ==="
LOG_HOST="${OUTDIR}/logcat_${NOW}.mlc.log"
$ADB_RUNNER -s "$DEVICE_ID" pull "$LOG_TMP_DEV" "$LOG_HOST"

# ───────────────────────────────────
# 3) Pull trace_*.json & delete on device
# ───────────────────────────────────
TRACE_OUTDIR="${OUTDIR}/traces"
mkdir -p "$TRACE_OUTDIR"

echo "=== Harvesting trace JSONs from ${TRACE_DEVICE_DIR} ==="
trace_list=$($ADB_RUNNER -s "$DEVICE_ID" shell "ls -1 ${TRACE_DEVICE_DIR}/${TRACE_PATTERN}" 2>/dev/null || true)

if [[ -z "$trace_list" ]]; then
  echo "No trace files found."
else
  count=$(wc -w <<<"$trace_list")
  echo "Pulling $count trace file(s) to ${TRACE_OUTDIR}"
  for f in $trace_list; do
    base=$(basename "$f")
    $ADB_RUNNER -s "$DEVICE_ID" pull "$f" "${TRACE_OUTDIR}/${base}"
    $ADB_RUNNER -s "$DEVICE_ID" shell rm -f "$f"
  done
fi

# ───────────────────────────────────
# 4) Clean up temp logcat on device
# ───────────────────────────────────
echo "=== Cleaning up device temp logcat ==="
$ADB_RUNNER -s "$DEVICE_ID" shell rm -f "$LOG_TMP_DEV"

echo "Done.  Logcat → ${LOG_HOST}"
echo "      Traces → ${TRACE_OUTDIR}"
