#!/bin/bash
set -e

echo "=== LM-TRACE VERCEL BUILD SCRIPT ==="

# Check if flutter is available in environment
if ! command -v flutter &> /dev/null; then
  echo "Flutter not found in PATH. Installing Flutter 3.41.9..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b 3.41.9 /tmp/flutter
  export PATH="$PATH:/tmp/flutter/bin"
fi

flutter --version
flutter config --enable-web

API_URL="${API_BASE_URL:-https://maanak-production.up.railway.app}"
echo "Building Flutter Web with API_BASE_URL: $API_URL"

flutter pub get
flutter build web --release --dart-define=API_BASE_URL="$API_URL"

echo "=== BUILD COMPLETED SUCCESSFULLY ==="
