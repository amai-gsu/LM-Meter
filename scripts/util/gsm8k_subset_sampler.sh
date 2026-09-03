
#!/bin/bash

# ==============================================================================
# Script: gsm8k_kl_sampler.sh
# Description:
#   This script generates KL-matched subsets from the GSM8K dataset using seeds
#   from 0 to maxseed. Only the top 3 subsets with the lowest KL divergence
#   (token length distribution) are retained.
# ==============================================================================

RATIO=0.1
KL=0.02
INPUT_PATH="/Users/haoxinwang/mobileLLM/Neurips25/evaluation/datasets/gsm8k/gsm8k_test.jsonl"
OUTPUT_FOLDER="/Users/haoxinwang/mobileLLM/Neurips25/evaluation/datasets/gsm8k/"
PLOT_DIR="$OUTPUT_FOLDER/figures"
maxseed=99
KL_FILE="gsm8k_kl_scores_temp.txt"
> "$KL_FILE"

for seed in $(seq 0 $maxseed); do
  echo "Running seed $seed..."
  KL_results=$(python /Users/haoxinwang/mobileLLM/Neurips25/evaluation/gsm8k_sampler.py     --seed "$seed"     --ratio "$RATIO"     --input "$INPUT_PATH"     --output "$OUTPUT_FOLDER"     --kl "$KL"     | awk '/KL divergence/ {print $NF}')
  echo "$seed $KL_results" >> "$KL_FILE"
done

echo -e "\n✅ Top 3 seeds with lowest KL divergence:"
sort -k2 -n "$KL_FILE" | head -n 3 | tee gsm8k_top3_seeds.txt

TOP3=$(cut -d' ' -f1 gsm8k_top3_seeds.txt)

echo -e "\n🧹 Cleaning up files not in top 3 seeds..."
for seed in $(seq 0 $maxseed); do
  if ! echo "$TOP3" | grep -qw "$seed"; then
    rm -f $OUTPUT_FOLDER/gsm8k_subset_kl*_ratio${RATIO}_seed${seed}.jsonl
    rm -f $PLOT_DIR/gsm8k_subset_kl*_ratio${RATIO}_seed${seed}_distribution.png
  fi
done

rm "$KL_FILE"
rm "gsm8k_top3_seeds.txt"
echo -e "\n✅ Done. Retained top 3 files and deleted the rest."
