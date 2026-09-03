#!/bin/bash
#chmod +x compile_models_mlc.sh

# =====================================================================
# MLC Model Conversion (compile) Script w/o Quantization
# https://llm.mlc.ai/docs/compilation/compile_models.html#compile-command-specification
# =====================================================================

# =====================================================================
# Config generation command follows the pattern below:
# mlc_llm gen_config \
#     CONFIG \
#     --quantization QUANTIZATION_MODE \
#     [--model-type MODEL_TYPE] \
#     --conv-template CONV_TEMPLATE \
#     [--context-window-size CONTEXT_WINDOW_SIZE] \
#     [--sliding-window-size SLIDING_WINDOW_SIZE] \
#     [--prefill-chunk-size PREFILL_CHUNK_SIZE] \
#     [--tensor-parallel-shard TENSOR_PARALLEL_SHARDS] \
#     --output OUTPUT

# CONFIG: Path to a HuggingFace model directory that contains a config.json;
# A config.json file in HuggingFace format defines the model architecture, 
# including the vocabulary size, the number of layers, the hidden size, 
# number of attention heads.

# --quantization: The quantization mode we use to compile. If unprovided, 
# will infer from MODEL; Available options are: q0f16, q0f32, q3f16_1, 
# q4f16_1, q4f32_1, and q4f16_awq;
# Note: if you don't need to quantize the model and want to retain the original
# model precision, you should use either --quantization q0f16 or --quantization q0f32;
# Check model's config.json ("torch_dtype": "float32") for its original precision.

# --model-type: Model architecture such as “llama”. If not set, it is 
# inferred from mlc-chat-config.json

# --conv-template: Conversation template. It depends on how the model is tuned;
# see https://github.com/mlc-ai/mlc-llm/blob/main/python/mlc_llm/model/model.py
# for pre-defined templates; you can also define your own's.

# --context-window-size : Option to provide the maximum sequence length supported 
# by the model. This is usually explicitly shown as context length or context window 
# in the model card. If this option is not set explicitly, by default, it will be 
# determined by context_window_size or max_position_embeddings in config.json, and 
# the latter is usually inaccurate for some models.

# --sliding-window-size: (Experimental) The sliding window size in sliding window 
# attention (SWA). This optional field overrides the sliding_window in config.json 
# for those models that use SWA. Currently only useful when compiling mistral-based models. 

# --prefill-chunk-size: The chunk size during prefilling. By default, the chunk size is the 
# same as context_window_size or sliding_window_size.

# --tensor-parallel-shard: Number of shards to split the model into in tensor parallelism 
# multi-gpu inference.
# =====================================================================

# =====================================================================
# MLC model compilation command follows the pattern: 
# mlc_llm compile \
#     MODEL \
#     [--quantization QUANTIZATION_MODE] \
#     [--model-type MODEL_TYPE] \
#     [--device DEVICE] \
#     [--host HOST] \
#     [--opt OPT] \
#     [--system-lib-prefix SYSTEM_LIB_PREFIX] \
#     --output OUTPUT \
#     [--overrides OVERRIDES]

# --overrides: Model configuration override. Configurations to override 
# mlc-chat-config.json. Supports context_window_size, prefill_chunk_size, 
# sliding_window, max_batch_size and tensor_parallel_shards. Meanwhile, 
# model config could be explicitly specified via details knobs, 
# e.g. --overrides "context_window_size=1024;prefill_chunk_size=128".
# max_gen_len???

#--debug-dump DEBUG_DUMP 
# =====================================================================


set -euo pipefail                       # safer defaults

Kernel_Duplication=false

MODELS_DIR="$HOME/mobileLLM/Models"
OUTPUT_ROOT_DIR="$MODELS_DIR/MLC"

convert_mlc() {
  local DEBUG=false                     # toggle “step 3” easily

  # ─── 1. Models and templates must align position-wise ────────────
  # local MODELS=(
  #   google_gemma-2-2b-it
  # )
  # local CONV_TEMPLATES=(
  #   gemma_instruction
  # )

   local MODELS=(
    google_gemma-1.1-2b-it
    # EleutherAI_pythia-70m
    # EleutherAI_pythia-160m
    # EleutherAI_pythia-410m
    # EleutherAI_pythia-1b
    # EleutherAI_pythia-1.4b
  )

  local CONV_TEMPLATES=(
    gemma_instruction
    # gpt2
    # gpt2
    # gpt2
    # gpt2
    # gpt2
  )

  # ─── 2. Targets and quantisation schemes ─────────────────────────
  local BACKENDS=( android )            # add metal / cuda … if needed
  local QUANTS=( q4f16_1 )      # q4f16_1, q3f16_1, q4f16_0, q0f16, q0bf16, q0f32

  for i in "${!MODELS[@]}"; do
    local MODEL="${MODELS[i]}"
    local CONV_TEMPLATE="${CONV_TEMPLATES[i]}"

    for QUANT in "${QUANTS[@]}"; do
      local CONVERTED_DIR="$OUTPUT_ROOT_DIR/${MODEL}-${QUANT}"
      echo "🔄  $MODEL  →  $QUANT  (template: $CONV_TEMPLATE)"

      # ── step 1: generate chat-config & processed tokenizer ────────
      mlc_llm gen_config  "$MODELS_DIR/$MODEL" \
        --quantization "$QUANT" \
        --conv-template "$CONV_TEMPLATE" \
        -o "$CONVERTED_DIR"

      # ── step 2: compile runtime library for each backend ──────────
      for BACKEND in "${BACKENDS[@]}"; do
        local EXTENSION=$([[ $BACKEND == metal ]] && echo "so" || echo "tar")

        if [[ $Kernel_Duplication == false ]]; then
          echo "📦  Compiling for $BACKEND"
          mlc_llm compile "$CONVERTED_DIR" \
            --device "$BACKEND" \
            -o "$CONVERTED_DIR/${MODEL}-${BACKEND}-${QUANT}.${EXTENSION}" \
            --debug-dump "$CONVERTED_DIR/ir_dump"
        elif [[ $Kernel_Duplication == true ]]; then
          echo "📦  Compiling for $BACKEND … with kernel duplication"
          mlc_llm compile "$CONVERTED_DIR" \
            --device "$BACKEND" \
            -o "$CONVERTED_DIR/${MODEL}-${BACKEND}-${QUANT}-dup.${EXTENSION}" \
            --debug-dump "$CONVERTED_DIR/ir_dump"
        fi
      done

      # ── step 3: convert weights (skipped if DEBUG=true) ───────────
      if [[ $DEBUG == false ]]; then
        echo "💾  Converting weights …"
        mlc_llm convert_weight  "$MODELS_DIR/$MODEL/config.json" \
          --device auto \
          --quantization "$QUANT" \
          -o "$CONVERTED_DIR"
      fi
      echo
    done
  done
}

convert_mlc
