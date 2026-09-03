
#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Need to run on 6000Ada server.
# Run lm-eval on a matrix of (MODEL × QUANT) using llama.cpp GGUF servers.
# Each server is started on its own port, evaluated, then torn down.
# ---------------------------------------------------------------------------
set -Eeuo pipefail
trap 'cleanup' INT TERM EXIT      # always run cleanup on Ctrl-C or normal exit

##############################  CONFIGURATION  ###############################
MODEL_DIR="${1:-/home/haoxin/mlc_eval/models}"   # argv-1 overrides default
CONDA_ENV=llamagpu             # name of your lm-eval environment

TASKS=(arc_easy arc_challenge hellaswag gsm8k)

MODELS=(
  amai-gsu_pythia-70m-Q4_0-GGUF
  amai-gsu_pythia-160m-Q4_0-GGUF
  amai-gsu_pythia-410m-Q4_0-GGUF
  amai-gsu_pythia-1b-Q4_0-GGUF
  amai-gsu_pythia-1.4b-Q4_0-GGUF
  amai-gsu_SmolLM2-135M-Instruct-Q4_0-GGUF
  amai-gsu_SmolLM2-360M-Instruct-Q4_0-GGUF
  amai-gsu_SmolLM2-1.7B-Instruct-Q4_0-GGUF
  amai-gsu_Qwen1.5-0.5B-Chat-Q4_0-GGUF
  amai-gsu_Qwen1.5-1.8B-Chat-Q4_0-GGUF
)
QUANTS=(q4_0)

N_GPU_LAYERS=100          # llama.cpp option
BASE_PORT=8866            # first port → 8866, 8867, …

###############################  HOUSEKEEPING  ###############################
declare -A PIDS           # map  key="model|quant" → PGID
TS=$(date +%Y%m%d_%H%M%S)

RESULT_DIR="/home/haoxin/mlc_eval/LLM_results/quant"
LOG_DIR="/home/haoxin/mlc_eval/LLM_results/logs"
mkdir -p "$RESULT_DIR" "$LOG_DIR"

# confirm dependencies up front
command -v curl jq lm-eval >/dev/null || {
  echo "❌  curl, jq, lm-eval required" >&2; exit 1; }

###############################  FUNCTIONS  ##################################
terminate_group() {          # TERM → 5 s → KILL
  local pgid="$1"            # positive number
  kill -TERM  -- "-$pgid" 2>/dev/null || return 0   # graceful
  sleep 5
  pkill -KILL -g  "$pgid"  2>/dev/null || true      # ensure
  kill -KILL  -- "-$pgid" 2>/dev/null || true       # belt & braces
}

wait_for_gone() {
  local pgid="$1" t=0
  while pgrep -g "$pgid" >/dev/null 2>&1; do
    # any survivors that are NOT zombies?
    if ! ps -o stat= -g "$pgid" | grep -vq '^Z'; then
      break           # only zombies left → safe (no GPU mem)
    fi
    (( t++ > 30 )) && { echo "⚠️  PGID $pgid still running after 30 s"; break; }
    sleep 1
  done
}

wait_until_ready() {
  local port="$1"  t=0
  while :; do
    for path in /health / /v1/models; do
      code=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:${port}${path}" || true)
      [[ $code == 200 ]] && return 0
    done
    (( t++ > 120 )) && { echo "❌ server on :$port never became healthy"; return 1; }
    sleep 1
  done
}

start_server() {
  local model="$1" quant="$2" port="$3"
  local gguf
  gguf=$(find "${MODEL_DIR}/${model}" -maxdepth 1 -type f -name "*${quant}.gguf" | head -n1)
  [[ -n $gguf ]] || { echo "❌  .gguf not found for $model $quant" >&2; exit 1; }

  local log="${LOG_DIR}/${model}__${quant}__${TS}.log"
  echo "▶️  Starting  ${model}-${quant}  on :$port"
  CUDA_VISIBLE_DEVICES=0 \
  setsid python3 -m llama_cpp.server \
        --model "$gguf" \
        --n_gpu_layers "$N_GPU_LAYERS" \
        --host 0.0.0.0 \
        --port "$port" \
        &>> "$log" &                     # <<< no pipeline, PGID = PID
  local pid=$!
  local pgid; pgid=$(ps -o pgid= -p "$pid" | tr -d ' ')
  PIDS["$model|$quant"]=$pgid

  wait_until_ready "$port"
}

run_eval() {
  local model="$1"  quant="$2"  port="$3"
  for task in "${TASKS[@]}"; do
    local out="${RESULT_DIR}/${model}__${quant}__${task}"
    echo "🧮  Evaluating  $model  $quant  on  $task"
    conda run -n "$CONDA_ENV" lm-eval \
      --model gguf \
      --model_args "base_url=http://127.0.0.1:${port}" \
      --tasks "$task" \
      --output_path "${out}.json"
  done
}

cleanup() {
  echo -e "\n🔻  Cleaning up servers ..."
  for pgid in "${PIDS[@]:-}"; do
    terminate_group "$pgid"
    wait_for_gone   "$pgid"
  done
}

################################  MAIN  ######################################
counter=0
for model in "${MODELS[@]}"; do
  for quant in "${QUANTS[@]}"; do
    port=$((BASE_PORT + counter))

    start_server "$model" "$quant" "$port"
    run_eval     "$model" "$quant" "$port"

    pgid="${PIDS["$model|$quant"]}"
    terminate_group "${PIDS["$model|$quant"]}"   # free GPU
    wait_for_gone   "$pgid"
    unset 'PIDS["'"$model|$quant"'"]'

    counter=$((counter + 1))
  done
done

echo -e "\n✅  All evaluations finished.\nResults ➜  $RESULT_DIR\nLogs    ➜  $LOG_DIR"
