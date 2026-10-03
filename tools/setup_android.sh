#!/usr/bin/env bash
# Richtet das Android-Projekt für WerkCalc ein (lokal und in GitHub Actions identisch).
#
# FESTGELEGT, nach der ersten Veröffentlichung NIE mehr ändern:
#   Package name / applicationId : de.werkcalc.werkcalc
#   Dart-Paket / Projektname     : werkcalc
#   Anzeigename                  : WerkCalc
# Für iOS später dieselbe Kennung verwenden:
#   flutter create --org de.werkcalc --project-name werkcalc --platforms=ios .
set -euo pipefail

if [ ! -d android ]; then
  flutter create --org de.werkcalc --project-name werkcalc --platforms=android .
fi

# Anzeigename unter dem App-Icon
MANIFEST=android/app/src/main/AndroidManifest.xml
sed -i.bak 's/android:label="[^"]*"/android:label="WerkCalc"/' "$MANIFEST"
rm -f "$MANIFEST.bak"

flutter pub get
dart run flutter_launcher_icons

echo "applicationId:"
grep -rn "applicationId" android/app/build.gradle* || true
