#!/usr/bin/env python3
"""Make the unused llama.framework Mach-O dependency weak.

AzooKey 0.11.2 can leave a strong LC_LOAD_DYLIB for llama.framework in an
extension binary even when Zenzai traits are disabled. No llama/ggml symbols are
used in this build, so the framework should be optional at launch.
"""
from pathlib import Path
import argparse
import struct

MH_MAGIC_64 = 0xFEEDFACF
LC_LOAD_DYLIB = 0x0000000C
LC_LOAD_WEAK_DYLIB = 0x80000018
LLAMA = b"@rpath/llama.framework/llama\x00"


def weak_link_llama(path: Path) -> int:
    path = Path(path)
    data = bytearray(path.read_bytes())
    if len(data) < 32:
        raise ValueError("Mach-O is too small")
    magic, = struct.unpack_from("<I", data, 0)
    if magic != MH_MAGIC_64:
        raise ValueError(f"Expected 64-bit little-endian Mach-O, got {magic:#x}")

    ncmds, = struct.unpack_from("<I", data, 16)
    offset = 32
    matches = 0

    for _ in range(ncmds):
        if offset + 8 > len(data):
            raise ValueError("Truncated load command table")
        cmd, cmdsize = struct.unpack_from("<II", data, offset)
        if cmdsize < 8 or offset + cmdsize > len(data):
            raise ValueError("Invalid Mach-O load command size")

        command = bytes(data[offset:offset + cmdsize])
        if LLAMA in command:
            if cmd == LC_LOAD_DYLIB:
                struct.pack_into("<I", data, offset, LC_LOAD_WEAK_DYLIB)
            elif cmd != LC_LOAD_WEAK_DYLIB:
                raise ValueError(f"Unexpected llama load command: {cmd:#x}")
            matches += 1
        offset += cmdsize

    if matches != 1:
        raise ValueError(f"Expected exactly one llama load command, found {matches}")

    path.write_bytes(data)
    return matches


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("binary", type=Path)
    args = parser.parse_args()
    weak_link_llama(args.binary)
    print(f"Weakened llama.framework dependency in {args.binary}")
