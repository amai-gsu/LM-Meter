#!/bin/bash

# Go to the Android project directory
cd /Users/haoxinwang/mobileLLM/mlc-llm/android/MLCChat || {
    echo "❌ Failed to navigate to MLCChat project directory."
    exit 1
}

# Build the debug APK
echo "🔧 Building the APK..."
./gradlew assembleDebug

if [ $? -ne 0 ]; then
    echo "❌ Build failed. Exiting."
    exit 1
fi

# Install the APK on a connected Android device
echo "📲 Installing APK on device..."
adb install -r app/build/outputs/apk/debug/app-debug.apk

if [ $? -eq 0 ]; then
    echo "✅ APK installed successfully."
else
    echo "❌ APK install failed."
fi
