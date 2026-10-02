from pathlib import Path
import stat
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).with_name('copy_licenses.py')

class CopyLicensesTests(unittest.TestCase):
    def test_duplicate_readonly_upstream_notices_remain_writable(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for prefix in ['.build/checkouts', 'build/DerivedData/SourcePackages/checkouts']:
                source = root / prefix / 'ExamplePackage/LICENSE'
                source.parent.mkdir(parents=True)
                source.write_text('Copyright Example\nMIT license notice\n')
                source.chmod(0o444)
            subprocess.run([sys.executable, str(SCRIPT)], cwd=root, check=True, capture_output=True)
            target = root / 'build/IPA/Payload/KurukuruKeyboard.app/ThirdPartyLicenses/ExamplePackage/LICENSE'
            self.assertIn('Copyright Example', target.read_text())
            self.assertTrue(target.stat().st_mode & stat.S_IWUSR, 'Destination must remain writable for duplicated notices')

if __name__ == '__main__':
    unittest.main()
