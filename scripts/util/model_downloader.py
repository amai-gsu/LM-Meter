#========================================================================================
# Hugging Face Model Downloader

# This script simplifies downloading one or more models from the 
# [Hugging Face Hub](https://huggingface.co/) for offline use, fine-tuning, quantization, 
# or deployment in frameworks like [MLC LLM](https://github.com/mlc-ai/mlc-llm), 
# [llama.cpp](https://github.com/ggerganov/llama.cpp), and others.

# - Downloads one or more Hugging Face models
# - Saves them to a local directory of your choice
# - Supports both public and private/gated models
# - Optionally forces re-downloads

# Command-Line Arguments
# | Argument        | Description                                                   | Required |
# |----------------|---------------------------------------------------------------|----------|
# | `--models, -m`  | List of Hugging Face model repo IDs (e.g., `meta-llama/Llama-2-7b-hf`) | ✅        |
# | `--download-dir, -d` | Output folder for saving downloaded models                  | ✅        |
# | `--force, -f`   | Force overwrite existing model files                          | ❌        |
# | `--token, -t`   | Hugging Face access token (for gated/private models)          | ❌        |

# ### ✅ Example
# python download.py \
#   -m google/gemma-2-2b mistralai/Mistral-7B-Instruct-v0.1 \
#   -d /Users/haoxinwang/mobileLLM/Models \
#   -f \
#   -t $(cat ~/.hf_token)
#========================================================================================

import argparse
import os
from pathlib import Path

from huggingface_hub import snapshot_download


def parse_args():
    parser = argparse.ArgumentParser(description="Download Hugging Face models to a local directory.")
    parser.add_argument(
        "-m", "--models",
        nargs="+",
        required=True,
        help="Model names to download (in Hugging Face format, e.g., 'meta-llama/Llama-2-7b-hf').",
    )
    parser.add_argument(
        "-d", "--download-dir",
        type=str,
        required=True,
        help="Directory to download the models to.",
    )
    parser.add_argument(
        "-f", "--force",
        action="store_true",
        help="Force re-download even if files exist.",
    )
    parser.add_argument(
        "-t", "--token",
        type=str,
        default=None,
        help="Optional Hugging Face access token for private models.",
    )
    return parser.parse_args()


def download_model(model: str, download_dir: Path, force: bool, token: str = None):
    target_path = download_dir / model.replace("/", "_")
    print(f"📦 Downloading model: {model} → {target_path}")
    
    try:
        model_path = snapshot_download(
            repo_id=model, # HF repo name
            local_dir=str(target_path), #Local target dir
            cache_dir=os.environ.get("TRANSFORMERS_CACHE", None),
            force_download=force,
            token=token,
        )
        print(f"✅ Downloaded {model} to: {model_path}")
    except Exception as e:
        print(f"❌ Failed to download {model}: {e}")


def main():
    args = parse_args()
    download_dir = Path(args.download_dir).expanduser().resolve()
    download_dir.mkdir(parents=True, exist_ok=True)

    for model in args.models:
        download_model(model, download_dir, args.force, args.token)


if __name__ == "__main__":
    main()



