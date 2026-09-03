import argparse
import json
import numpy as np
from transformers import AutoTokenizer

def compute_mean_length(jsonl_path: str, field: str = "question"):
    # Initialize tokenizer (GPT-2 BPE, same as GPT-Neo)
    tokenizer = AutoTokenizer.from_pretrained("EleutherAI/gpt-neo-125M")

    lengths = []
    with open(jsonl_path, "r", encoding="utf-8") as f:
        for line in f:
            item = json.loads(line)
            text = item.get(field, "").strip()
            if not text:
                continue
            # Tokenize and record length
            ids = tokenizer(text)["input_ids"]
            lengths.append(len(ids))

    if not lengths:
        print("No valid prompts found.")
        return

    mean_len = np.mean(lengths)
    std_len = np.std(lengths)
    count = len(lengths)

    print(f"Processed {count} prompts")
    print(f"Mean prompt length: {mean_len:.2f} tokens")
    print(f"Std  prompt length: {std_len:.2f} tokens")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Compute mean prompt length for GSM8K JSONL file")
    parser.add_argument("jsonl_path", type=str, help="Path to GSM8K test JSONL file")
    parser.add_argument("--field", type=str, default="question",
                        help="JSON field containing the prompt text (default: 'question')")
    args = parser.parse_args()

    compute_mean_length(args.jsonl_path, args.field)
