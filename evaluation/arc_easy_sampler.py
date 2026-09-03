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

def kl_matched_subset(
    input_file: str,
    output_base: str,
    subset_ratio: float = 0.10,
    kl_threshold: float = 0.02,
    num_bins: int = 30,
    base_seed: int = 42
):
    # 1) load the ARC-Easy JSONL
    with open(input_file, "r") as f:
        data = [json.loads(line) for line in f]

    # 2) tokenizer for computing token lengths on the question stem
    tokenizer = AutoTokenizer.from_pretrained("EleutherAI/gpt-neo-125M")

    for item in data:
        # Use the 'question' field for length
        stem = item.get("question", "")
        item["input_length"] = len(tokenizer(stem)["input_ids"])

    # 3) build full distribution
    lengths_full = [item["input_length"] for item in data]
    hist_full, bin_edges = np.histogram(lengths_full, bins=num_bins, density=True)

    # 4) reproducible shuffle
    modifier = os.path.basename(output_base)
    seed = get_random_seed(base_seed, modifier)
    rng = random.Random(seed)
    indices = list(range(len(data)))
    rng.shuffle(indices)

    # 5) select KL-matched subset
    target_size = int(len(data) * subset_ratio)
    subset = []
    hist_subset = np.zeros(num_bins)

    for idx in indices:
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

    # 6) plot distributions
    plt.rcParams["font.family"] = "serif"
    plt.rcParams["font.serif"]  = ["Times New Roman"]
    hist_subset_norm = hist_subset / len(subset)
    final_kl = compute_kl(hist_subset_norm, hist_full)

    plot_dir = os.path.join(os.path.dirname(output_base), "figures")
    os.makedirs(plot_dir, exist_ok=True)

    fig, ax = plt.subplots(figsize=(5, 3), dpi=300)
    ax.hist(lengths_full, bins=bin_edges, alpha=0.5,
            label="Full dataset", density=True)
    ax.hist([x["input_length"] for x in subset],
            bins=bin_edges, alpha=0.5,
            label="Sampled subset", density=True)
    ax.legend(frameon=False, fontsize=13, loc="best")
    ax.set_xlabel("Token length", fontsize=16)
    ax.set_ylabel("Density", fontsize=16)
    ax.tick_params(axis='both', labelsize=14)
    ax.grid(False)
    plt.tight_layout()

    plot_file = os.path.join(
        plot_dir,
        f"arc_easy_subset_kl{final_kl:.4f}_ratio{subset_ratio}_seed{base_seed}_distribution.png"
    )
    plt.savefig(plot_file)
    print(f"Saved distribution plot to {plot_file}")

    # 7) write subset out as JSONL
    output_file = os.path.join(
        os.path.dirname(output_base),
        f"arc_easy_subset_kl{final_kl:.4f}_ratio{subset_ratio}_seed{base_seed}.jsonl"
    )
    with open(output_file, "w") as f:
        for item in subset:
            json.dump(item, f)
            f.write("\n")

    print(f"Saved {len(subset)} examples to {output_file}")
    print(f"Final KL divergence: {final_kl:.4f}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Select a KL-matched subset of ARC-Easy by token-length distribution"
    )
    parser.add_argument(
        "--input", type=str, required=True,
        help="Path to full ARC-Easy JSONL file"
    )
    parser.add_argument(
        "--output", type=str, required=True,
        help="Base path for outputs (no extension)"
    )
    parser.add_argument(
        "--ratio", type=float, default=0.10,
        help="Subset ratio (default: 0.10)"
    )
    parser.add_argument(
        "--kl", type=float, default=0.02,
        help="KL divergence threshold (default: 0.02)"
    )
    parser.add_argument(
        "--seed", type=int, default=42,
        help="Base random seed (default: 42)"
    )
    args = parser.parse_args()

    kl_matched_subset(
        args.input,
        args.output,
        subset_ratio=args.ratio,
        kl_threshold=args.kl,
        base_seed=args.seed
    )
