#!/bin/bash

# Local destination directory
DEST_DIR="/Users/haoxinwang/mobileLLM/Neurips25/results"

# Remote source directory
REMOTE_DIR="/storage/emulated/0/Documents/event_profile"

# Create local destination if it doesn't exist
mkdir -p "$DEST_DIR"

echo "🔄 Pulling files from Android..."
adb pull "${REMOTE_DIR}/." "$DEST_DIR"

if [ $? -eq 0 ]; then
    echo "✅ Files pulled successfully to $DEST_DIR"

    echo "🧹 Cleaning up files on Android device..."
    adb shell rm -f ${REMOTE_DIR}/*
    echo "✅ Cleanup complete."
else
    echo "❌ Failed to pull files from Android. No cleanup performed."
fi
