#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
BUILD_DIR="$PWD/build"
mkdir -p "$BUILD_DIR"
xcodegen generate
xcodebuild -project KurukuruKeyboard.xcodeproj -scheme KurukuruKeyboard \
  -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' \
  -archivePath "$BUILD_DIR/KurukuruKeyboard.xcarchive" \
  -derivedDataPath "$BUILD_DIR/DerivedData" \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY='' \
  archive 2>&1 | tee "$BUILD_DIR/xcodebuild.log"
APP="$BUILD_DIR/KurukuruKeyboard.xcarchive/Products/Applications/KurukuruKeyboard.app"
test -d "$APP"
# Package only the real device archive, not source or simulator output.
mkdir -p "$BUILD_DIR/IPA/Payload"
ditto "$APP" "$BUILD_DIR/IPA/Payload/KurukuruKeyboard.app"
python3 scripts/copy_licenses.py
# ARM64 linker signatures are ad-hoc, not Apple distribution/development
# identities. Do not treat a successful `codesign -d` as Apple signing.
# Preserve the native executable. An installer must re-sign app AND extension.
: > "$BUILD_DIR/signing-report.txt"
for bundle in "$BUILD_DIR/IPA/Payload/KurukuruKeyboard.app/PlugIns/"*.appex "$BUILD_DIR/IPA/Payload/KurukuruKeyboard.app"; do
  info="$(codesign --display --verbose=4 "$bundle" 2>&1 || true)"
  printf '%s\n%s\n\n' "$bundle" "$info" | tee -a "$BUILD_DIR/signing-report.txt"
  if printf '%s\n' "$info" | grep -q '^Authority='; then
    echo "Unexpected signing authority in unsigned build: $bundle" >&2
    exit 1
  fi
  if test -f "$bundle/embedded.mobileprovision"; then
    echo "Unexpected provisioning profile: $bundle" >&2
    exit 1
  fi
done
(cd "$BUILD_DIR/IPA" && zip -qry ../GuruGuruKeyBoard-unsigned.ipa Payload)
python3 scripts/validate_ipa.py "$BUILD_DIR/GuruGuruKeyBoard-unsigned.ipa" | tee "$BUILD_DIR/ipa-report.json"
(cd "$BUILD_DIR" && shasum -a 256 GuruGuruKeyBoard-unsigned.ipa > SHA256SUMS.txt)
