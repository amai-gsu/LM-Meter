from datasets import load_dataset

# Load the TEST split of ARC-Easy
# ds_test = load_dataset("ai2_arc", "ARC-Easy", split="test")
ds_test = load_dataset("ai2_arc", "ARC-Challenge", split="test")

# Write it out as JSONL (one example per line)
# ds_test.to_json("arc_easy_test.jsonl", orient="records", lines=True)
ds_test.to_json("arc_challenge_test.jsonl", orient="records", lines=True)
