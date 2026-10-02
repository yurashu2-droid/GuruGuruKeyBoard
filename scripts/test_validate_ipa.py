import importlib.util
import pathlib
import plistlib
import tempfile
import unittest
import zipfile

VALIDATOR = pathlib.Path(__file__).with_name('validate_ipa.py')


class ValidateIPATests(unittest.TestCase):
    def load_validator(self):
        self.assertTrue(VALIDATOR.exists(), 'IPA validator is not implemented')
        spec = importlib.util.spec_from_file_location('validate_ipa', VALIDATOR)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module

    def make_ipa(self, path, *, extension=True, dictionary=True, platform='iPhoneOS'):
        # Temporary structural fixture only; never shipped as an application.
        with zipfile.ZipFile(path, 'w') as archive:
            root = 'Payload/Test.app/'
            common = {'CFBundleExecutable': 'Test', 'CFBundleIdentifier': 'com.example.test', 'CFBundlePackageType': 'APPL', 'CFBundleSupportedPlatforms': [platform], 'MinimumOSVersion': '16.0'}
            archive.writestr(root + 'Info.plist', plistlib.dumps(common))
            archive.writestr(root + 'Test', b'\xcf\xfa\xed\xfe' + (0x0100000c).to_bytes(4, 'little') + b'\0' * 32)
            if extension:
                ext = root + 'PlugIns/Keyboard.appex/'
                props = dict(common, CFBundleExecutable='Keyboard', CFBundleIdentifier='com.example.test.keyboard', CFBundlePackageType='XPC!', NSExtension={'NSExtensionPointIdentifier': 'com.apple.keyboard-service', 'NSExtensionAttributes': {'RequestsOpenAccess': False}})
                archive.writestr(ext + 'Info.plist', plistlib.dumps(props))
                archive.writestr(ext + 'Keyboard', b'\xcf\xfa\xed\xfe' + (0x0100000c).to_bytes(4, 'little') + b'\0' * 32)
                if dictionary:
                    archive.writestr(ext + 'AzooKey.bundle/Dictionary/louds/test.louds', b'test fixture')

    def test_rejects_missing_extension(self):
        module = self.load_validator()
        with tempfile.TemporaryDirectory() as d:
            path = pathlib.Path(d) / 'test.ipa'
            self.make_ipa(path, extension=False)
            with self.assertRaises(ValueError):
                module.inspect_ipa(path)

    def test_rejects_missing_dictionary(self):
        module = self.load_validator()
        with tempfile.TemporaryDirectory() as d:
            path = pathlib.Path(d) / 'test.ipa'
            self.make_ipa(path, dictionary=False)
            with self.assertRaises(ValueError):
                module.inspect_ipa(path)

    def test_rejects_simulator_bundle(self):
        module = self.load_validator()
        with tempfile.TemporaryDirectory() as d:
            path = pathlib.Path(d) / 'test.ipa'
            self.make_ipa(path, platform='iPhoneSimulator')
            with self.assertRaises(ValueError):
                module.inspect_ipa(path)

    def test_accepts_expected_structure(self):
        module = self.load_validator()
        with tempfile.TemporaryDirectory() as d:
            path = pathlib.Path(d) / 'test.ipa'
            self.make_ipa(path)
            report = module.inspect_ipa(path)
            self.assertEqual(report['bundle_id'], 'com.example.test')
            self.assertEqual(report['architecture'], 'arm64')
            self.assertEqual(report['signing'], 'unsigned')


if __name__ == '__main__':
    unittest.main()
