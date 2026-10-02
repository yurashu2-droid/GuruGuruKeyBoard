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

# AzooKey 0.11.2 links llama.framework into the IME executable, but Xcode does
# not embed that binary-target framework in this app-extension arrangement.
# Without it, dyld terminates the keyboard before viewDidLoad and iOS falls
# straight back to the previous keyboard.
IME="$APP/PlugIns/KurukuruIMEExtension.appex"
test -d "$IME"

LLAMA_FRAMEWORK="$(
  find "$BUILD_DIR/DerivedData/SourcePackages/artifacts" \
    -type d -name 'llama.framework' -path '*ios-arm64*' -print -quit 2>/dev/null || true
)"
if test -z "$LLAMA_FRAMEWORK"; then
  LLAMA_FRAMEWORK="$(
    find "$BUILD_DIR/DerivedData/SourcePackages/artifacts" \
      -type d -name 'llama.framework' -print -quit 2>/dev/null || true
  )"
fi
if test -z "$LLAMA_FRAMEWORK" || ! test -d "$LLAMA_FRAMEWORK"; then
  echo "llama.framework required by KurukuruIMEExtension was not found" >&2
  exit 1
fi

mkdir -p "$IME/Frameworks"
rm -rf "$IME/Frameworks/llama.framework"
ditto "$LLAMA_FRAMEWORK" "$IME/Frameworks/llama.framework"

# This artifact is intentionally unsigned. Remove any upstream signature so
# SideStore/AltStore/etc. can re-sign the complete nested bundle consistently.
codesign --remove-signature "$IME/Frameworks/llama.framework" >/dev/null 2>&1 || true
rm -rf "$IME/Frameworks/llama.framework/_CodeSignature"
rm -f "$IME/Frameworks/llama.framework/embedded.mobileprovision"

# Package only the real device archive, not source or simulator output.
rm -rf "$BUILD_DIR/IPA"
mkdir -p "$BUILD_DIR/IPA/Payload"
ditto "$APP" "$BUILD_DIR/IPA/Payload/KurukuruKeyboard.app"
python3 scripts/copy_licenses.py

# ARM64 linker signatures are ad-hoc, not Apple distribution/development
# identities. Do not treat a successful codesign -d as Apple signing.
: > "$BUILD_DIR/signing-report.txt"

check_unsigned_bundle() {
  local bundle="$1"
  local info
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
}

for bundle in "$BUILD_DIR/IPA/Payload/KurukuruKeyboard.app/PlugIns/"*.appex "$BUILD_DIR/IPA/Payload/KurukuruKeyboard.app"; do
  check_unsigned_bundle "$bundle"
done

for framework in "$BUILD_DIR/IPA/Payload/KurukuruKeyboard.app/PlugIns/KurukuruIMEExtension.appex/Frameworks/"*.framework; do
  test -d "$framework" || continue
  check_unsigned_bundle "$framework"
done

(cd "$BUILD_DIR/IPA" && zip -qry ../GuruGuruKeyBoard-unsigned.ipa Payload)
python3 scripts/validate_ipa.py "$BUILD_DIR/GuruGuruKeyBoard-unsigned.ipa" | tee "$BUILD_DIR/ipa-report.json"
(cd "$BUILD_DIR" && shasum -a 256 GuruGuruKeyBoard-unsigned.ipa > SHA256SUMS.txt)
