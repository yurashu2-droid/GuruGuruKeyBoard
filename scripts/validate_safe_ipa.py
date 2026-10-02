#!/usr/bin/env python3
"""Validate the dependency-free startup-isolation IPA."""
import hashlib
import json
from pathlib import Path
import plistlib
import struct
import sys
import zipfile

path = Path(sys.argv[1])
with zipfile.ZipFile(path) as archive:
    bad = archive.testzip()
    if bad:
        raise SystemExit(f"Corrupt ZIP member: {bad}")
    names = archive.namelist()
    app_plists = [n for n in names if n.startswith("Payload/") and n.count("/") == 2 and n.endswith(".app/Info.plist")]
    if len(app_plists) != 1:
        raise SystemExit("Expected exactly one app")
    root = app_plists[0][:-len("Info.plist")]
    app = plistlib.loads(archive.read(app_plists[0]))
    ext_plists = [n for n in names if n.startswith(root + "PlugIns/") and n.endswith(".appex/Info.plist") and n.count("/") == 4]
    if len(ext_plists) != 1:
        raise SystemExit("Expected exactly one app extension")
    ext_entry = ext_plists[0]
    ext = plistlib.loads(archive.read(ext_entry))
    if ext.get("NSExtension", {}).get("NSExtensionPointIdentifier") != "com.apple.keyboard-service":
        raise SystemExit("Embedded extension is not a keyboard")
    extroot = ext_entry[:-len("Info.plist")]

    for base, props in [(root, app), (extroot, ext)]:
        exe = props.get("CFBundleExecutable")
        data = archive.read(base + exe)
        if data[:4] != b"\xcf\xfa\xed\xfe" or struct.unpack_from("<I", data, 4)[0] != 0x0100000C:
            raise SystemExit("Expected thin ARM64 Mach-O")

    forbidden = [
        n for n in names
        if "AzooKey" in n or "swift-transformers" in n or "/Dictionary/" in n
    ]
    if forbidden:
        raise SystemExit("Diagnostic keyboard unexpectedly contains conversion dependencies")

    signatures = [n for n in names if "/_CodeSignature/" in n or n.endswith("/embedded.mobileprovision")]
    if signatures:
        raise SystemExit("Expected unsigned diagnostic artifact")

report = {
    "file": path.name,
    "bytes": path.stat().st_size,
    "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
    "version": app.get("CFBundleShortVersionString"),
    "keyboard_display_name": ext.get("CFBundleDisplayName"),
    "architecture": "arm64",
    "conversion_dependencies": "absent",
    "zip_integrity": "passed",
}
print(json.dumps(report, ensure_ascii=False, indent=2))
