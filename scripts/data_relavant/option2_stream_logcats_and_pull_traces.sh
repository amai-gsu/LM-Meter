#!/usr/bin/env bash

#                  ┌────────────────────────┐
#                  │      Android Device    │
#                  │                        │
#                  │  • logcat (TVM/MLC)    │
#                  │  • trace_*.json        │
#                  └──────────┬─────────────┘
#                             │ adb
#                             │
#         ┌───────────────────┴───────────────────┐
#         │                                       │
# ┌───────▼─────────┐                  ┌──────────▼─────────┐
# │  Host Machine   │                  │  Host Machine      │
# │  (Log Output)   │                  │  (Trace Files)     │
# │                 │                  │                    │
# │  tvm_mlc.log    │                  │  traces/           │
# │                 │                  │  └─ trace_*.json   │
# └─────────────────┘                  └────────────────────┘


# Android Log & Trace Collection

# This workflow collects **runtime logs** and **structured trace JSONs** from an Android device during on-device LLM inference (via MLC/TVM runtime).

# ---

# ## 1. What the Bash Script Does

# - **Clears old traces** on the device (`trace_*.json`).
# - **Clears logcat buffers** to start fresh.
# - **Streams logs** with tags `TVM_RUNTIME`, `MLC_Profile`, `MLC_EVENT` into a host file:
#   - `tvm_mlc.log`
# - **Captures structured traces** from the device (`trace_*.json`), stored under:
#   - `.../option2_<timestamp>/traces/`
# - **Organizes output** under a timestamped experiment directory.

# ---

# ## 2. What’s Stored in the JSON Files?

# Each `trace_*.json` contains a list of **trace events**, typically in the Chrome/Perfetto trace format.

# ### Common Fields
# - **`name`** → event name, e.g. `"request added to engine (0)"`, `"prefill"`, `"decode"`, kernel name.  
# - **`ph`** → event type (*phase*):  
#   - `"B"` = begin  
#   - `"E"` = end  
#   - `"X"` = complete  
#   - `"i"` = instant  
# - **`ts`** → timestamp (microseconds since boot).  
# - **`pid`** → process ID on device.  
# - **`tid`** → thread ID (to disambiguate parallel events).  
# - **Custom fields** (depends on instrumentation): kernel duration, number of tokens, arguments, memory usage, etc.

# ### Example Snippet
# ```json
# [
#   {
#     "name": "request added to engine (0)",
#     "ph": "i",
#     "ts": 1750274382114019,
#     "pid": 1,
#     "tid": "768885e9-1458-440a-95a3"
#   },
#   {
#     "name": "decode_kernel",
#     "ph": "X",
#     "ts": 1750274383114019,
#     "dur": 5234,
#     "pid": 1,
#     "tid": 12,
#     "args": {
#       "tokens": 128,
#       "latency_ms": 5.23
#     }
#   }
# ]

# -------- 

set -euo pipefail
# ───────────────────────────────────
# Config / environment defaults
# ───────────────────────────────────
ADB_RUNNER=${ADB_RUNNER:-adb}

# first connected device if DEVICE_ID not preset
DEVICE_ID=${DEVICE_ID:-$($ADB_RUNNER devices | grep -v List | cut -f1 | head -n1)}

OUTFILE_ROOT=${OUTFILE_ROOT:-"$HOME/Research/LM-Meter/Code-private/test/logcat"}
TRACE_DEVICE_DIR=${TRACE_DEVICE_DIR:-"/sdcard/Download"}  # where the app writes trace_*.json
TRACE_PATTERN="trace_*.json"

NOW=$(date +"%Y%m%d%H%M%S")
OUTDIR="${OUTFILE_ROOT}/option2_${NOW}"
mkdir -p "${OUTDIR}"

# ───────────────────────────────────
# 0) Remove any existing trace files on the Android device
# ───────────────────────────────────
echo "=== Removing any existing trace files from ${TRACE_DEVICE_DIR} on device ==="
$ADB_RUNNER -s "$DEVICE_ID" shell "rm -f ${TRACE_DEVICE_DIR}/${TRACE_PATTERN}" 2>/dev/null || true

# ───────────────────────────────────
# Functions
# ───────────────────────────────────
cleanup_logcat() {
  echo "=== Stopping logcat (pid=$LOGCAT_PID) ==="
  kill "$LOGCAT_PID" 2>/dev/null || true
}

pull_traces() {
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
}


# ───────────────────────────────────
# 0) Clear existing logcat buffers
# ───────────────────────────────────
echo "=== Clearing device logcat buffers ==="
$ADB_RUNNER -s "$DEVICE_ID" logcat -c

# ───────────────────────────────────
# 1) Stream TVM_RUNTIME, MLC_Profile & MLC_EVENT logs to host
# ───────────────────────────────────
echo "=== Streaming TVM_RUNTIME, MLC_Profile, MLC_EVENT logcat → ${OUTDIR}/tvm_mlc.log ==="
LOG_HOST="${OUTDIR}/tvm_mlc.log"
$ADB_RUNNER -s "$DEVICE_ID" logcat \
    -b main \
    -v raw \
    "TVM_RUNTIME:I" \
    "MLC_Profile:D" \
    "MLC_EVENT:D" \
    "*:S" \
    > "$LOG_HOST" &
LOGCAT_PID=$!

# trap Ctrl-C to clean up logcat and then pull traces
trap 'cleanup_logcat; pull_traces; exit 0' SIGINT

echo "Logcat streaming started (pid $LOGCAT_PID)."
echo "Run your workload now; when it finishes, exit this script or press Ctrl-C."

# wait for the logcat process (or Ctrl-C)
wait

# ───────────────────────────────────
# 2) Normal exit: clean up and pull traces
# ───────────────────────────────────
cleanup_logcat
pull_traces

echo "=== All done ==="
echo "Log file:     ${LOG_HOST}"
echo "Trace files:  ${OUTDIR}/traces/"

