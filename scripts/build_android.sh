#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
flutter pub get --enforce-lockfile
flutter analyze
flutter test
flutter build apk --release
mkdir -p dist/android
cp build/app/outputs/flutter-apk/app-release.apk dist/android/WordContacts.apk
