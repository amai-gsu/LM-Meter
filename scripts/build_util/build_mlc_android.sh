#!/bin/bash
#chmod +x ./build_util/build_mlc_android.sh

# Exit immediately on error
set -e

# Colors for clarity
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
RESET='\033[0m'

# -----------------------------------
# Step 1: Set environment variables
# -----------------------------------
echo -e "${YELLOW}[STEP 1] Setting environment variables...${RESET}"

echo "TVM_SOURCE_DIR = $TVM_SOURCE_DIR"
echo "MLC_LLM_SOURCE_DIR = $MLC_LLM_SOURCE_DIR"
echo

# -----------------------------------
# Step 2: Clean build directories (if exist)
# -----------------------------------
echo -e "${YELLOW}[STEP 2] Cleaning previous build artifacts...${RESET}"
rm -rf "$MLC_LLM_SOURCE_DIR/android/MLCChat/build" || true
rm -rf "$MLC_LLM_SOURCE_DIR/android/mlc4j/build" || true
echo "Cleaned build directories."
echo

# -----------------------------------
# Step 3: Navigate to MLCChat directory
# -----------------------------------
echo -e "${YELLOW}[STEP 3] Navigating to MLCChat directory...${RESET}"
cd "$MLC_LLM_SOURCE_DIR/android/MLCChat" || {
  echo -e "${RED}Error: MLCChat directory not found.${RESET}"
  exit 1
}
echo "Current directory: $(pwd)"
echo

# -----------------------------------
# Step 4: Package MLC LLM runtime and model libs
# -----------------------------------
echo -e "${YELLOW}[STEP 4] Building and packaging MLC LLM...${RESET}"
if ! command -v mlc_llm &> /dev/null; then
  echo -e "${RED}Error: 'mlc_llm' command not found in PATH.${RESET}"
  exit 1
fi
mlc_llm package
echo

# -----------------------------------
# Step 5: Build the Android APK using Gradle
# -----------------------------------
echo -e "${YELLOW}[STEP 5] Building Android APK with Gradle...${RESET}"
if [ ! -f ./gradlew ]; then
  echo -e "${RED}Error: gradlew script not found.${RESET}"
  exit 1
fi
./gradlew assembleDebug
echo

# -----------------------------------
# Step 6: Install APK to connected Android device
# -----------------------------------
echo -e "${YELLOW}[STEP 6] Installing APK via ADB...${RESET}"
APK_PATH="app/build/outputs/apk/debug/app-debug.apk"
if [ ! -f "$APK_PATH" ]; then
  echo -e "${RED}Error: APK not found at $APK_PATH${RESET}"
  exit 1
fi
adb install -r "$APK_PATH"
echo

echo -e "${GREEN}[DONE] App built and deployed successfully!${RESET}"
