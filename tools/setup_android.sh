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
  rm -f test/widget_test.dart  # Standard-Test von flutter create passt nicht zu WerkCalc
fi

# Anzeigename unter dem App-Icon
MANIFEST=android/app/src/main/AndroidManifest.xml
sed -i.bak 's/android:label="[^"]*"/android:label="WerkCalc"/' "$MANIFEST"
rm -f "$MANIFEST.bak"

# Feste Debug-Signatur: Jede neue APK lässt sich über die alte installieren
# (ohne Deinstallieren, Daten bleiben erhalten). Kein Geheimnis: Test-Schlüssel.
mkdir -p "$HOME/.android"
cp tools/debug.keystore "$HOME/.android/debug.keystore"

# Berechtigungen für Spracheingabe (Mikrofon) und Spracherkennungsdienst
python3 - <<'PY'
import re
p = "android/app/src/main/AndroidManifest.xml"
s = open(p, encoding="utf-8").read()
if "RECORD_AUDIO" not in s:
    s = s.replace("<application", '<uses-permission android:name="android.permission.RECORD_AUDIO"/>\n    <application', 1)
if "RecognitionService" not in s:
    q = '<queries>\n        <intent><action android:name="android.speech.RecognitionService"/></intent>\n    </queries>\n'
    if "<queries>" in s:
        s = s.replace("<queries>", q.split("\n")[0] + "\n        <intent><action android:name=\"android.speech.RecognitionService\"/></intent>", 1)
    else:
        s = s.replace("</manifest>", "    " + q + "</manifest>")
open(p, "w", encoding="utf-8").write(s)
PY

# Mindest-Android 24 (ML-Kit Texterkennung, Spracheingabe)
for f in android/app/build.gradle android/app/build.gradle.kts; do
  [ -f "$f" ] && sed -i -E 's/minSdk(Version)? ?=? ?flutter\.minSdkVersion/minSdk = 24/' "$f"
done || true

flutter pub get
dart run flutter_launcher_icons

echo "applicationId:"
grep -rn "applicationId" android/app/build.gradle* || true
