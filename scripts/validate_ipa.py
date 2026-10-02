#!/usr/bin/env python3
"""Inspect an unsigned device IPA containing one or more keyboard extensions."""
import argparse
import hashlib
import json
from pathlib import Path
import plistlib
import struct
import zipfile


def inspect_ipa(path: Path) -> dict:
    path = Path(path)
    with zipfile.ZipFile(path) as archive:
        bad = archive.testzip()
        if bad:
            raise ValueError(f'Corrupt ZIP member: {bad}')

        names = archive.namelist()
        app_plists = [
            n for n in names
            if n.startswith('Payload/') and n.count('/') == 2 and n.endswith('.app/Info.plist')
        ]
        if len(app_plists) != 1:
            raise ValueError('Expected exactly one Payload/*.app/Info.plist')

        root = app_plists[0][:-len('Info.plist')]
        app = plistlib.loads(archive.read(app_plists[0]))
        if app.get('CFBundleSupportedPlatforms') != ['iPhoneOS']:
            raise ValueError('Not an iPhoneOS device app')

        bundle_id = app.get('CFBundleIdentifier', '')
        if not bundle_id:
            raise ValueError('Missing app bundle ID')

        def validate_binary(base: str, props: dict) -> None:
            executable = props.get('CFBundleExecutable', '')
            if not executable or '/' in executable:
                raise ValueError('Invalid executable name')
            data = archive.read(base + executable)
            if len(data) < 32 or data[:4] != b'\xcf\xfa\xed\xfe':
                raise ValueError('Expected a thin 64-bit Mach-O executable')
            if struct.unpack_from('<I', data, 4)[0] != 0x0100000c:
                raise ValueError('Expected ARM64 executable')

        validate_binary(root, app)

        ext_plists = [
            n for n in names
            if n.startswith(root + 'PlugIns/')
            and n.endswith('.appex/Info.plist')
            and n.count('/') == 4
        ]

        keyboards = []
        for entry in ext_plists:
            props = plistlib.loads(archive.read(entry))
            extension = props.get('NSExtension', {})
            if extension.get('NSExtensionPointIdentifier') != 'com.apple.keyboard-service':
                continue

            ext_bundle_id = props.get('CFBundleIdentifier', '')
            if not ext_bundle_id.startswith(bundle_id + '.'):
                raise ValueError('Extension bundle ID must extend the app bundle ID')
            if props.get('CFBundleSupportedPlatforms') != ['iPhoneOS']:
                raise ValueError('Extension is not built for iPhoneOS')
            if extension.get('NSExtensionAttributes', {}).get('RequestsOpenAccess') is not False:
                raise ValueError('Unexpected full-access request')

            extroot = entry[:-len('Info.plist')]
            validate_binary(extroot, props)

            dictionaries = [
                n for n in names
                if n.startswith(extroot)
                and '/Dictionary/' in n
                and n.endswith('.louds')
                and archive.getinfo(n).file_size > 0
            ]

            llama_framework = False
            if ext_bundle_id.endswith('.ime'):
                llama_binary = extroot + 'Frameworks/llama.framework/llama'
                if llama_binary not in names:
                    raise ValueError('IME keyboard is missing llama.framework required by dyld')
                data = archive.read(llama_binary)
                if len(data) < 32 or data[:4] != b'\xcf\xfa\xed\xfe':
                    raise ValueError('llama.framework is not a thin 64-bit Mach-O')
                if struct.unpack_from('<I', data, 4)[0] != 0x0100000c:
                    raise ValueError('llama.framework is not ARM64')
                llama_framework = True

            keyboards.append({
                'bundle_id': ext_bundle_id,
                'display_name': props.get('CFBundleDisplayName'),
                'dictionary_files': len(dictionaries),
                'llama_framework': llama_framework
            })

        if not keyboards:
            raise ValueError('Expected at least one embedded custom keyboard extension')

        # Preserve the original one-keyboard validator behaviour for its unit
        # fixture, while allowing diagnostic multi-keyboard builds where only
        # the IME variant carries the azooKey dictionary.
        if len(keyboards) == 1 and keyboards[0]['dictionary_files'] == 0:
            raise ValueError('Keyboard conversion dictionary is missing')

        ime = [k for k in keyboards if k['bundle_id'].endswith('.ime')]
        if ime and any(k['dictionary_files'] == 0 for k in ime):
            raise ValueError('IME keyboard conversion dictionary is missing')

        signatures = [
            n for n in names
            if '/_CodeSignature/' in n or n.endswith('/embedded.mobileprovision')
        ]
        if signatures:
            raise ValueError('Expected an unsigned artifact without a provisioning profile')

        return {
            'file': path.name,
            'bytes': path.stat().st_size,
            'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
            'bundle_id': bundle_id,
            'version': app.get('CFBundleShortVersionString'),
            'minimum_ios': app.get('MinimumOSVersion'),
            'architecture': 'arm64',
            'signing': 'unsigned',
            'keyboard_extensions': keyboards,
            'zip_integrity': 'passed'
        }


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('ipa', type=Path)
    args = parser.parse_args()
    print(json.dumps(inspect_ipa(args.ipa), ensure_ascii=False, indent=2))
