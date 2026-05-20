#!/bin/bash

# Script to fix nfc_manager Kotlin deprecation issue
# Run this after: flutter pub cache clean OR flutter pub get (if nfc_manager was updated)

NFC_FILE="$HOME/.pub-cache/hosted/pub.dev/nfc_manager-3.5.0/android/src/main/kotlin/io/flutter/plugins/nfcmanager/Translator.kt"

if [ -f "$NFC_FILE" ]; then
    echo "✅ Found nfc_manager plugin"
    
    # Check if already fixed
    if grep -q "toLowerCase" "$NFC_FILE"; then
        echo "🔧 Applying fix..."
        sed -i '' 's/toLowerCase(Locale.ROOT)/lowercase(Locale.ROOT)/g' "$NFC_FILE"
        echo "✅ Fix applied successfully!"
    else
        echo "✅ Already fixed!"
    fi
else
    echo "❌ nfc_manager 3.5.0 not found in pub cache"
    echo "Run: flutter pub get first"
fi

