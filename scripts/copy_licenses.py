"""Include upstream copyright/license notices from resolved dependencies."""
from pathlib import Path
import os
import shutil

output = Path('build/IPA/Payload/KurukuruKeyboard.app/ThirdPartyLicenses')
count = 0
for prefix in [Path('.build/checkouts'), Path('build/DerivedData/SourcePackages/checkouts')]:
    if not prefix.is_dir():
        continue
    for root, directories, filenames in os.walk(prefix):
        directories[:] = [d for d in directories if d != '.git']
        for name in filenames:
            if not name.upper().startswith(('LICENSE', 'COPYING', 'NOTICE')):
                continue
            source = Path(root) / name
            if not source.is_file() or source.is_symlink():
                continue
            destination = output / source.relative_to(prefix)
            destination.parent.mkdir(parents=True, exist_ok=True)
            # SwiftPM checkout notices may be read-only. Preserve bytes, not mode.
            if destination.exists():
                destination.chmod(0o644)
            shutil.copyfile(source, destination)
            count += 1
if count == 0:
    raise SystemExit('No upstream license notices collected')
print(f'Included {count} dependency license/notice files')
