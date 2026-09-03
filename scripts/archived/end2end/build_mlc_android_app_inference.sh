#!/bin/bash

# Exit on any error
set -e

# -----------------------------------
# Step 1: Set environment variables
# -----------------------------------
echo "[STEP 1] Setting environment variables..."
export MLC_LLM_SOURCE_DIR=/Users/haoxinwang/mobileLLM/MLC_krl/mlc-llm-inf
export TVM_SOURCE_DIR=/Users/haoxinwang/mobileLLM/MLC_krl/tvm-v0_20_dev0

echo "TVM_SOURCE_DIR set to: $TVM_SOURCE_DIR"
echo "MLC_LLM_SOURCE_DIR set to: $MLC_LLM_SOURCE_DIR"
echo

# -----------------------------------
# Step 2: Navigate to MLCChat directory
# -----------------------------------
echo "[STEP 2] Navigating to MLCChat project directory..."
cd "$MLC_LLM_SOURCE_DIR/android/MLCChat"
echo "Current directory: $(pwd)"
echo

# -----------------------------------
# Step 3: Package MLC LLM runtime and model libs
# -----------------------------------
echo "[STEP 3] Running 'mlc_llm package' to build and bundle native libs..."
mlc_llm package
echo

# -----------------------------------
# Step 4: Build the Android app using Gradle
# -----------------------------------
echo "[STEP 4] Building Android APK with Gradle..."
./gradlew assembleDebug
echo

# -----------------------------------
# Step 5: Install APK to connected Android device
# -----------------------------------
echo "[STEP 5] Installing APK to Android device via ADB..."
adb install -r app/build/outputs/apk/debug/app-debug.apk
echo

echo "[DONE] App built and deployed successfully!"
