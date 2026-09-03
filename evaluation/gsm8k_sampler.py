
import json
import random
import numpy as np
import matplotlib.pyplot as plt
from transformers import AutoTokenizer
from scipy.stats import entropy
import argparse
import os
import hashlib

def compute_kl(subset_hist, full_hist):
    return entropy(subset_hist + 1e-10, full_hist + 1e-10)

def get_random_seed(base_seed, modifier):
    combined = f"{base_seed}_{modifier}"
    return int(hashlib.md5(combined.encode()).hexdigest(), 16) % (10**8)

def kl_matched_subset(input_file, output_base, subset_ratio=0.10, kl_threshold=0.02, num_bins=30, base_seed=42):
    with open(input_file, "r") as f:
        data = [json.loads(line) for line in f]

    tokenizer = AutoTokenizer.from_pretrained("EleutherAI/gpt-neo-125M")

    for item in data:
        item["input_length"] = len(tokenizer(item["question"])["input_ids"])

    lengths_full = [item["input_length"] for item in data]
    hist_full, bin_edges = np.histogram(lengths_full, bins=num_bins, density=True)

    modifier = os.path.basename(output_base)
    seed = get_random_seed(base_seed, modifier)
    rng = random.Random(seed)
    shuffled_indices = list(range(len(data)))
    rng.shuffle(shuffled_indices)

    target_size = int(len(data) * subset_ratio)
    subset = []
    hist_subset = np.zeros(num_bins)

    for idx in shuffled_indices:
        item = data[idx]
        bin_idx = np.digitize(item["input_length"], bin_edges) - 1
        bin_idx = min(max(bin_idx, 0), num_bins - 1)

        temp_hist = hist_subset.copy()
        temp_hist[bin_idx] += 1
        temp_hist_norm = temp_hist / (len(subset) + 1)

        kl_score = compute_kl(temp_hist_norm, hist_full)

        if kl_score <= kl_threshold or len(subset) < target_size:
            subset.append(item)
            hist_subset = temp_hist

        if len(subset) >= target_size and kl_score <= kl_threshold:
            break

    plt.rcParams["font.family"] = "serif"
    plt.rcParams["font.serif"]  = ["Times New Roman"]
    hist_subset_norm = hist_subset / len(subset)
    final_kl = compute_kl(hist_subset_norm, hist_full)

    plot_dir = os.path.join(os.path.dirname(output_base), "figures")
    os.makedirs(plot_dir, exist_ok=True)

    fig, ax = plt.subplots(figsize=(5, 3), dpi=300)
    plt.hist(lengths_full, bins=bin_edges, alpha=0.5, label="Full dataset", density=True)
    plt.hist([x["input_length"] for x in subset], bins=bin_edges, alpha=0.5, label="Sampled subset", density=True)
    plt.xlabel("Token length", fontsize=16)
    plt.ylabel("Density", fontsize=16)
    ax.tick_params(axis='both', labelsize=14) 
    # plt.legend(frameon=False, fontsize=13, loc='best')
    plt.grid(False)
    plt.tight_layout()
    plot_file = os.path.join(plot_dir, f"gsm8k_subset_kl{final_kl:.4f}_ratio{subset_ratio}_seed{base_seed}_distribution.png")
    plt.savefig(plot_file)
    print(f"Distribution plot saved to {plot_file}")

    output_file = os.path.join(os.path.dirname(output_base), f"gsm8k_subset_kl{final_kl:.4f}_ratio{subset_ratio}_seed{base_seed}.jsonl")
    with open(output_file, "w") as f:
        for item in subset:
            json.dump(item, f)
            f.write("\n")

    print(f"Saved {len(subset)} examples to {output_file}")
    print(f"KL divergence: {final_kl:.4f}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=str, required=True, help="Path to full GSM8K JSONL file")
    parser.add_argument("--output", type=str, required=True, help="Base name for output files (no extension)")
    parser.add_argument("--ratio", type=float, default=0.10, help="Subset ratio (default 0.10)")
    parser.add_argument("--kl", type=float, default=0.02, help="KL divergence threshold (default 0.02)")
    parser.add_argument("--seed", type=int, default=42, help="Base random seed")
    args = parser.parse_args()

    kl_matched_subset(args.input, args.output, subset_ratio=args.ratio, kl_threshold=args.kl, base_seed=args.seed)
