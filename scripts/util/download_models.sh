#!/bin/bash
#chmod +x download_models.sh

#========================================================================
# Run this script to download one or more models into your local project 
# directory for post-training quantization and MLC/llama.cpp deployment.
#========================================================================

DOWNLOAD_SCRIPT_PATH="/Users/haoxinwang/mobileLLM/Neurips25/scripts/util"
OUTPUT_PATH="/Users/haoxinwang/mobileLLM/Models"
HUGGINGFACE_TOKEN=$(cat ~/.hf_token)

# MODELS=(
#     "google/gemma-2-2b-it"
# )

MODELS=(
    # "EleutherAI/pythia-70m"
    # "EleutherAI/pythia-160m"
    # "EleutherAI/pythia-410m"
    # "EleutherAI/pythia-1b"
    # "EleutherAI/pythia-1.4b"
    "google/gemma-1.1-2b-it"
)

for MODEL in "${MODELS[@]}"; do
    echo "🔽 Downloading model: $MODEL"
    python "${DOWNLOAD_SCRIPT_PATH}/model_downloader.py" \
        -m "${MODEL}" \
        -d "${OUTPUT_PATH}" \
        -t "${HUGGINGFACE_TOKEN}"
done