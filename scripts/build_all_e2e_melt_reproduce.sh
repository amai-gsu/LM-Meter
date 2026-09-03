#!/bin/bash

set -euo pipefail
trap 'echo "❌ Error on line $LINENO. Exiting."' ERR

# ROOT="/Users/haoxinwang/Research/LM-Meter/Code-private"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "📂 Project root detected: $ROOT"
cd "$ROOT/scripts"

echo "=== Building Customized TVM ==="
export TVM_HOME="$ROOT/codebase/tvm-v0_20_dev0"
./build_util/build_customized_tvm.sh

echo "=== Building MLC Kernel with Kernel-level Profiling==="
export TVM_HOME="$ROOT/codebase/tvm-v0_20_dev0"
export MLC_HOME="$ROOT/codebase/mlc-llm-kernel"
export KERNEL_LEVEL_PROFILE="1"
./build_util/build_mlc.sh

echo "=== Building MLC Kernel Android App with Kernel-level Profiling==="
export MLC_LLM_SOURCE_DIR="$ROOT/codebase/mlc-llm-kernel"
export TVM_SOURCE_DIR="$ROOT/codebase/tvm-v0_20_dev0"
./build_util/build_mlc_android.sh

echo "✅ All builds completed successfully ==="


# ---- Back up for old Macbook ---
# cd /Users/haoxinwang/mobileLLM/Neurips25/scripts

# echo "=== Building Customized TVM ==="
# export TVM_HOME="/Users/haoxinwang/mobileLLM/MLC_krl/tvm-v0_20_dev0"
# ./build_util/build_customized_tvm.sh

# echo "=== Building MLC Kernel with Kernel-level Profiling==="
# export TVM_HOME="/Users/haoxinwang/mobileLLM/MLC_krl/tvm-v0_20_dev0"
# export MLC_HOME="/Users/haoxinwang/mobileLLM/MLC_krl/mlc-llm-kernel"
# export KERNEL_LEVEL_PROFILE="1"
# ./build_util/build_mlc.sh

# echo "=== Building MLC Kernel Android App with Kernel-level Profiling==="
# export MLC_LLM_SOURCE_DIR="/Users/haoxinwang/mobileLLM/MLC_krl/mlc-llm-kernel"
# export TVM_SOURCE_DIR="/Users/haoxinwang/mobileLLM/MLC_krl/tvm-v0_20_dev0"
# ./build_util/build_mlc_android.sh

# echo "✅ All builds completed successfully ==="

