# python prompt4runtime.py --input datasets/gsm8k/gsm8k_subset_kl0.0368_ratio0.1_seed74.jsonl \
# --output datasets/gsm8k/mobile/prompt.json \
# --task gsm8k

# import json
# import argparse
# import re

# def clean_tags_hellaswag(text):
#     """Removes HellaSwag-specific structural tags like [header], [title], [step], [substeps]."""
#     return re.sub(r"\[(header|title|step|substeps)\]\s*", "", text)

# def format_hellaswag(example, clean=False):
#     ctx = example["ctx"].strip()
#     if clean:
#         ctx = clean_tags_hellaswag(ctx)
#     return f"{ctx} Then,"

# def format_gsm8k(example, clean=False):
#     question = example["question"].strip()
#     return question  # Optionally add "Let's think step by step." for CoT prompts

# def convert_to_android_prompt(input_path, output_path, dataset_type="hellaswag", clean=False):
#     prompts = []

#     # Choose the formatter based on dataset type
#     if dataset_type == "hellaswag":
#         formatter = format_hellaswag
#     elif dataset_type == "gsm8k":
#         formatter = format_gsm8k
#     else:
#         raise ValueError(f"Unsupported dataset type: {dataset_type}")

#     with open(input_path, "r") as f:
#         for line in f:
#             example = json.loads(line)
#             prompt = formatter(example, clean=clean)
#             prompts.append([prompt])  # Android format expects List[List[str]]

#     with open(output_path, "w") as f:
#         json.dump(prompts, f, indent=2)

# def main():
#     parser = argparse.ArgumentParser()
#     parser.add_argument("--input", required=True, help="Path to input .jsonl file")
#     parser.add_argument("--output", required=True, help="Path to output prompts.json file")
#     parser.add_argument("--task", required=True, choices=["hellaswag", "gsm8k"], help="Dataset task")
#     parser.add_argument("--clean_tags", action="store_true", help="Whether to clean HellaSwag tags like [step], [title]")
#     args = parser.parse_args()

#     convert_to_android_prompt(args.input, args.output, args.task, clean=args.clean_tags)

# if __name__ == "__main__":
#     main()

import json
import argparse
import re

def clean_tags_hellaswag(text):
    """Removes HellaSwag-specific structural tags like [header], [title], [step], [substeps]."""
    return re.sub(r"\[(header|title|step|substeps)\]\s*", "", text)

def format_hellaswag(example, clean=False):
    ctx = example["ctx"].strip()
    if clean:
        ctx = clean_tags_hellaswag(ctx)
    return f"{ctx} Then,"

def format_gsm8k(example, clean=False):
    question = example["question"].strip()
    return question  # Optionally: add " Let's think step by step."

def format_arc(example, clean=False):
    """Formats ARC-Easy or ARC-Challenge as a question plus enumerated choices."""
    q = example.get("question", "").strip()
    choices = example.get("choices", {}).get("text", [])
    # Label choices A, B, C, … on separate lines
    options = [f"{chr(65+i)}. {c.strip()}" for i, c in enumerate(choices)]
    return q + "\n" + "\n".join(options)

def convert_to_android_prompt(input_path, output_path, dataset_type="hellaswag", clean=False):
    prompts = []

    # Choose the formatter based on dataset type
    if dataset_type == "hellaswag":
        formatter = format_hellaswag
    elif dataset_type == "gsm8k":
        formatter = format_gsm8k
    elif dataset_type in ("arc_easy", "arc_challenge"):
        formatter = format_arc
    else:
        raise ValueError(f"Unsupported dataset type: {dataset_type}")

    with open(input_path, "r") as f:
        for line in f:
            example = json.loads(line)
            prompt = formatter(example, clean=clean)
            prompts.append([prompt])  # Android format expects List[List[str]]

    with open(output_path, "w") as f:
        json.dump(prompts, f, indent=2)
    print(f"Written {len(prompts)} prompts to {output_path}")

def main():
    parser = argparse.ArgumentParser(
        description="Convert a sampled JSONL into Android prompts.json"
    )
    parser.add_argument(
        "--input", required=True,
        help="Path to input .jsonl file"
    )
    parser.add_argument(
        "--output", required=True,
        help="Path to output prompts.json file"
    )
    parser.add_argument(
        "--task", required=True,
        choices=["hellaswag", "gsm8k", "arc_easy", "arc_challenge"],
        help="Dataset task"
    )
    parser.add_argument(
        "--clean_tags", action="store_true",
        help="Whether to clean HellaSwag tags like [step], [title]"
    )
    args = parser.parse_args()

    convert_to_android_prompt(
        args.input,
        args.output,
        dataset_type=args.task,
        clean=args.clean_tags
    )

if __name__ == "__main__":
    main()

