#!/bin/bash
# ==============================================================================
# Description:
#   Generate KL-matched subsets from the ARC–Easy dataset using a list of seeds.
#   For each seed we:
#     1) Sample a subset whose token-length histogram best matches the full ARC–Easy.
#     2) Record the resulting KL divergence.
#   After evaluating all seeds:
#     – Keep only the top 3 seeds with lowest KL divergence.
#     – Delete all other subset files and plots.
#     – Convert each retained subset into mobile-friendly prompts via prompt4runtime.py.
#
# Inputs:
#   – ARC–Easy JSONL: arc_easy_train.jsonl (or whichever split you choose)
#   – Python scripts:
#       • arc_easy_sampler.py      (renamed version of hellaswag_sampler.py)
#       • prompt4runtime.py        (same prompt converter)
#
# Outputs:
#   – Top 3 KL-matched subsets (.jsonl)
#   – Corresponding distribution plots (.png)
#   – Android-ready prompts (.json)
#
# Usage:
#   ./arc_easy_pipeline.sh
# ==============================================================================

set -euo pipefail

#### Configuration ####
RATIO=0.10
KL=0.02
MAXSEED=6

INPUT_PATH="/Users/haoxinwang/mobileLLM/Neurips25/evaluation/datasets/arc_easy/arc_easy_test.jsonl"
OUTPUT_DIR="/Users/haoxinwang/mobileLLM/Neurips25/evaluation/datasets/arc_easy"
PLOT_DIR="$OUTPUT_DIR/figures"
MOBILE_DIR="$OUTPUT_DIR/mobile"

# temp file for logging <seed> <KL>
KL_LOG="$(mktemp)"
> "$KL_LOG"

mkdir -p "$PLOT_DIR" "$MOBILE_DIR"

#### 1) Run sampler for each seed ####
for seed in $(seq 0 "$MAXSEED"); do
  echo "==> Seed $seed"
  # sampler should print a line like "Final KL divergence: 0.0123"
  kl_val=$(python /Users/haoxinwang/mobileLLM/Neurips25/evaluation/arc_easy_sampler.py \
    --input  "$INPUT_PATH" \
    --output "$OUTPUT_DIR/arc_easy" \
    --ratio   "$RATIO" \
    --kl      "$KL" \
    --seed    "$seed" \
    2>&1 \
    | awk '/Final KL divergence/ {print $NF}')
  echo "$seed $kl_val" >> "$KL_LOG"
done

#### 2) Find top 3 seeds ####
echo -e "\nTop 3 seeds by lowest KL:"
TOP3=$(sort -k2n "$KL_LOG" | head -n3 | tee top3_seeds.txt | awk '{print $1}')
echo

#### 3) Clean up non-top3 subsets & plots ####
echo "Cleaning up other seeds..."
for seed in $(seq 0 "$MAXSEED"); do
  if ! grep -qx "$seed" <<<"$TOP3"; then
    rm -f "$OUTPUT_DIR"/arc_easy_subset_kl*"_ratio${RATIO}_seed${seed}.jsonl"
    rm -f "$PLOT_DIR"/arc_easy_subset_kl*"_ratio${RATIO}_seed${seed}_distribution.png"
  fi
done
echo "Done cleanup."

#### 4) Convert retained subsets to mobile prompts ####
echo -e "\nConverting top 3 subsets to mobile prompts..."
for seed in $TOP3; do
  subset_file=$(ls "$OUTPUT_DIR"/arc_easy_subset_kl*"_ratio${RATIO}_seed${seed}.jsonl" 2>/dev/null)
  if [[ -f "$subset_file" ]]; then
    out_json="$MOBILE_DIR/prompts_arc_easy_seed${seed}.json"
    python /Users/haoxinwang/mobileLLM/Neurips25/evaluation/prompt4runtime.py \
      --input     "$subset_file" \
      --output    "$out_json" \
      --task      arc_easy \
      --clean_tags
    echo "→ Created $out_json"
  else
    echo "⚠️  No subset for seed $seed found; skipping."
  fi
done

# teardown
rm top3_seeds.txt "$KL_LOG"

echo -e "\n✅ Pipeline complete. Retained seeds: $TOP3"
