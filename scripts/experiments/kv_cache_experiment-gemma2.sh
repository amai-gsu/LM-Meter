#!/bin/bash
set -euo pipefail  # safer defaults

MODELS_DIR="$HOME/mobileLLM/Models"
OUTPUT_ROOT_DIR="$MODELS_DIR/MLC"

CTX_WINDOW_SIZE=256
PREFILL_CHUNK_SIZE=256

convert_mlc() {
  # ─── 1. Models and templates must align position-wise ────────────
  local MODELS=(
    google_gemma-2-2b-it
  )
  local CONV_TEMPLATES=(
    gemma_instruction
  )

  # ─── 2. Targets and quantisation schemes ─────────────────────────
  local BACKENDS=( android )            # add metal / cuda … if needed
  local QUANTS=( q4f16_1 )              # q4f16_1, q3f16_1, q4f16_0

  for i in "${!MODELS[@]}"; do
    local MODEL="${MODELS[i]}"
    local CONV_TEMPLATE="${CONV_TEMPLATES[i]}"

    for QUANT in "${QUANTS[@]}"; do
      local CONVERTED_DIR="$OUTPUT_ROOT_DIR/${MODEL}-${QUANT}"
      echo "🔄  $MODEL  →  $QUANT  (template: $CONV_TEMPLATE)"

      # ── step 1: generate chat-config & processed tokenizer ────────
      mlc_llm gen_config "$MODELS_DIR/$MODEL" \
        --quantization "$QUANT" \
        --conv-template "$CONV_TEMPLATE" \
        --prefill-chunk-size "$PREFILL_CHUNK_SIZE" \
        --context-window-size "$CTX_WINDOW_SIZE" \
        -o "$CONVERTED_DIR"

      echo
      echo "👉  Now edit these two fields (to the same desired value) in:"
      echo "      $CONVERTED_DIR/mlc-chat-config.json"
      echo "    • \"context_window_size\""
      echo "    • \"sliding_window\""
      echo
      read -p "Once done, press [Enter] to continue with compilation…"

      # ── step 2: compile runtime library for each backend ──────────
      for BACKEND in "${BACKENDS[@]}"; do
        local EXTENSION=$([[ $BACKEND == metal ]] && echo "so" || echo "tar")
        echo "📦  Compiling for $BACKEND …"
        mlc_llm compile "$CONVERTED_DIR" \
          --device "$BACKEND" \
          --overrides "context_window_size=$CTX_WINDOW_SIZE;prefill_chunk_size=$PREFILL_CHUNK_SIZE" \
          -o "$CONVERTED_DIR/${MODEL}-${BACKEND}-${QUANT}.${EXTENSION}" \
          --debug-dump "$CONVERTED_DIR/ir_dump"
      done

    # # ── step 3: convert weights ───────────
    #   echo "💾  Converting weights …"
    #   mlc_llm convert_weight  "$MODELS_DIR/$MODEL/config.json" \
    #     --device auto \
    #     --quantization "$QUANT" \
    #     -o "$CONVERTED_DIR"
    done
  done
}

convert_mlc
