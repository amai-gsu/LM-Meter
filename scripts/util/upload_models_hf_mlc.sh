#!/bin/bash
#chmod +x upload_models_hf_mlc.sh

#========================================================================
# Run this script to upload compiled/converted MLC to HuggingFace, so we
# can directly download the model weights on Android/iOS app via editing
# mlc-package-config.json. An example:
# {
#     "device": "android",
#     "model_list": [
#         {
#             "model": "HF://mlc-ai/Qwen2.5-1.5B-Instruct-q4f16_1-MLC",
#             "estimated_vram_bytes": 3980990464,
#             "model_id": "Qwen2.5-1.5B-Instruct-q4f16_1-MLC"

#         },
#         {
#             "model": "HF://mlc-ai/gemma-2-2b-it-q4f16_1-MLC",
#             "model_id": "gemma-2-2b-it-q4f16_1-MLC",
#             "estimated_vram_bytes": 3000000000
#         },
#          {
            #  ADD NEW model ...
#          }

#     ]
# }
#========================================================================

#========================================================================
# Step 1: Log in & install LFS, Make sure you have Git LFS and the HF CLI.
# pip install git-lfs huggingface-hub
# git lfs install
# huggingface-cli login
# When prompted, paste in the token you can create on 
# https://huggingface.co/settings/tokens.

# Step 2: Create a new model repo on Hugging Face, click “New model”

# Step 3: Clone your fresh repo to the local dir
# git clone https://huggingface.co/amai-gsu/model_name
# cd model_name

# Step 4: Copy in the compiled/converted weights
# cp -a /path/to/compiled_model/* .

# Step 5: Commit and Push
# git add .
# git commit -m "Add weights"
# git push origin main 
#========================================================================

#========================================================================
# Issue fixed: 
# remote: ----------------------------------------------------------------
# remote: Your push was rejected because it contains files larger than 10 MiB.
# remote: Please use https://git-lfs.github.com/ to store large files.
# remote: See also: https://hf.co/docs/hub/repositories-getting-started#terminal
# remote: 
# remote: Offending files:
# remote:   - tokenizer.json (ref: refs/heads/main)
# remote: ----------------------------------------------------------------

# Step 1: Stop tracking tokenizer.json in plain Git & mark it for LFS
# git rm --cached tokenizer.json
# git lfs track "tokenizer.json"

# Step 2: Re-add and amend your commit
# git add .gitattributes tokenizer.json
# git commit --amend -C HEAD

# Step 3: Push again
# git push origin main --force
#========================================================================
