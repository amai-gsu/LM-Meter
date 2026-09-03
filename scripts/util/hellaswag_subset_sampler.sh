#!/bin/bash

# ==============================================================================
# Description:
#   This script generates KL-matched subsets from the HellaSwag validation set
#   using a predefined list of random seeds. For each seed, it samples a subset
#   of the data and calculates the KL divergence between the subset’s token 
#   length distribution and the full dataset’s distribution.
#
#   After all seeds are evaluated:
#     - Only the top 3 seeds with the lowest KL divergence are retained.
#     - All other subsets and their plots are deleted.
#     - Each retained subset is then converted into Android-friendly prompts
#       (formatted as JSON files) for on-device evaluation.
#
# Inputs:
#   - HellaSwag val set: hellaswag_val.jsonl
#   - Python scripts:
#       - hellaswag_sampler.py: generates KL-matched subsets
#       - prompt4runtime.py: converts subsets into prompts.json for Android
#
# Outputs:
#   - Top 3 KL-matched subsets (.jsonl)
#   - Corresponding distribution plots (.png)
#   - Android-ready prompts (.json) saved to /mobile/
#
# Usage Notes:
#   - Seeds are explicitly specified (not a range)
#   - Requires Python and the listed scripts to be correctly configured
# ==============================================================================

# Define fixed arguments
RATIO=0.01
KL=0.02
INPUT_PATH="/Users/haoxinwang/mobileLLM/Neurips25/evaluation/datasets/hellaswag/hellaswag_val.jsonl"
OUTPUT_FOLDER="/Users/haoxinwang/mobileLLM/Neurips25/evaluation/datasets/hellaswag/"
PLOT_DIR="$OUTPUT_FOLDER/figures"
maxseed=9
# Temporary file to hold KL values
KL_FILE="kl_scores_temp.txt"
> "$KL_FILE"  # Clear the file

for seed in $(seq 0 $maxseed); do
# for seed in 8 61 94; do
  echo "Running seed $seed..."
  KL_results=$(python /Users/haoxinwang/mobileLLM/Neurips25/evaluation/hellaswag_sampler.py \
    --seed "$seed" \
    --ratio "$RATIO" \
    --input "$INPUT_PATH" \
    --output "$OUTPUT_FOLDER" \
    --kl "$KL" \
    | grep -i "kl divergence" | grep -o "[0-9.]*")

    # Append to KL score log
  echo "$seed $KL_results" >> "$KL_FILE"
done

# 2. Extract top 3 seeds with lowest KL
echo -e "\n✅ Top 3 seeds with lowest KL divergence:"
sort -k2 -n "$KL_FILE" | head -n 3 | tee top3_seeds.txt

# Get only the seed numbers
TOP3=$(cut -d' ' -f1 top3_seeds.txt)

# 3. Clean up files not in top 3
echo -e "\n🧹 Cleaning up files not in top 3 seeds..."
for seed in $(seq 0 $maxseed); do
  if ! echo "$TOP3" | grep -qw "$seed"; then
    # Delete JSONL file
    JSONL_FILE="$OUTPUT_FOLDER/hellaswag_subset_kl"*"_ratio${RATIO}_seed${seed}.jsonl"
    rm -f $JSONL_FILE

    # Delete distribution plot
    PNG_FILE="$PLOT_DIR/hellaswag_subset_kl"*"_ratio${RATIO}_seed${seed}_distribution.png"
    rm -f $PNG_FILE
  fi
done

echo -e "\n✅ Done. Retained top 3 files and deleted the rest."
rm "$KL_FILE"
rm "top3_seeds.txt"

# 4. Convert top 3 subset files to prompts.json for mobile
echo -e "\n📲 Converting top 3 subsets to mobile prompts..."

MOBILE_DIR="$OUTPUT_FOLDER/mobile"
mkdir -p "$MOBILE_DIR"

for seed in $TOP3; do
  # Use shell globbing to find the actual file path
  MATCHED_FILE=$(ls "$OUTPUT_FOLDER"/hellaswag_subset_kl*_ratio${RATIO}_seed${seed}.jsonl 2>/dev/null)

  if [ -f "$MATCHED_FILE" ]; then
    OUTPUT_PROMPT="$MOBILE_DIR/prompts_hellaswag_seed${seed}.json"
    python /Users/haoxinwang/mobileLLM/Neurips25/evaluation/prompt4runtime.py \
      --input "$MATCHED_FILE" \
      --output "$OUTPUT_PROMPT" \
      --task hellaswag \
      --clean_tags
    echo "✅ Created prompt file: $OUTPUT_PROMPT"
  else
    echo "❌ Subset file for seed $seed not found, skipping..."
  fi
done
