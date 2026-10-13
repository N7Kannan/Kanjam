#!/usr/bin/env bash
# Generates the Android host project with YOUR Flutter version (so Gradle/AGP
# settings always match your toolchain), then applies KANJAM branding:
# app name, launcher icons and a dark launch screen.
#
# Usage (from the project root):   bash tools/setup_android.sh
set -euo pipefail
cd "$(dirname "$0")/.."

command -v flutter >/dev/null 2>&1 || { echo "flutter was not found on your PATH"; exit 1; }

if [ -d android ]; then
  echo "android/ already exists - keeping it and only re-applying branding."
else
  tmp="$(mktemp -d)"
  # --org + --project-name give the same application id as the original APK: com.kanjam.finance
  flutter create --org com.kanjam --project-name finance --platforms=android "$tmp/scaffold"
  cp -R "$tmp/scaffold/android" ./android
  rm -rf "$tmp"
fi

manifest="android/app/src/main/AndroidManifest.xml"
sed -i.bak -E 's/android:label="[^"]*"/android:label="KANJAM"/' "$manifest" && rm -f "$manifest.bak"

# Launcher icons recovered from the original APK.
cp -R android_overrides/res/. android/app/src/main/res/

# Black launch background so a dark app does not flash white on start.
for dir in drawable drawable-v21; do
  mkdir -p "android/app/src/main/res/$dir"
  cat > "android/app/src/main/res/$dir/launch_background.xml" <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@android:color/black" />
</layer-list>
XML
done

echo
echo "Android project ready (application id com.kanjam.finance)."
echo "Next:  flutter pub get && dart fix --apply && flutter analyze && flutter test && flutter build apk --release"
