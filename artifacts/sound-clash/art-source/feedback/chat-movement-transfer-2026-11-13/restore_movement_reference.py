#!/usr/bin/env python3
"""Restore the owner-authorized Feedback movement reference; standard library only."""
from pathlib import Path
import argparse
import base64
import hashlib
import io
import json
import zipfile

ARCHIVE_SHA256 = "88a553374f253e8d8298f1f6cb674a8166a888734d45fb5dc2bd0c03f299f747"
FILES = {
    "01_contact_a.webp", "02_pass_a.webp", "03_contact_b.webp",
    "04_pass_b_rear_arm.png", "Feedback_Walk_132BPM_Preferred.mp4",
    "reference-manifest.json",
}

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check-only", action="store_true",
                        help="Validate the complete package without writing restored files.")
    args = parser.parse_args()
    here = Path(__file__).resolve().parent
    encoded = "".join((here / ("part-%02d.b64" % i)).read_text().strip()
                      for i in range(1, 5))
    data = base64.b64decode(encoded, validate=True)
    if hashlib.sha256(data).hexdigest() != ARCHIVE_SHA256:
        raise RuntimeError("Archive hash mismatch; no restored files written.")
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        names = archive.namelist()
        if len(names) != len(FILES) or set(names) != FILES:
            raise RuntimeError("Unexpected/duplicate archive entries; no files written.")
        if sum(i.file_size for i in archive.infolist()) > 20_000_000:
            raise RuntimeError("Unexpected archive size; no files written.")
        payload = {name: archive.read(name) for name in names}
    manifest = json.loads(payload["reference-manifest.json"])
    if set(manifest["sha256"]) != FILES - {"reference-manifest.json"}:
        raise RuntimeError("Manifest file list mismatch; no files written.")
    for name, digest in manifest["sha256"].items():
        if hashlib.sha256(payload[name]).hexdigest() != digest:
            raise RuntimeError("Media hash mismatch: " + name)
    destination = here / "movement-reference"
    # Preflight every destination before creating or changing any restored file.
    if destination.is_symlink():
        raise RuntimeError("Destination is a symlink; no files written.")
    for name, content in payload.items():
        target = destination / name
        if target.is_symlink() or (target.exists() and
                (not target.is_file() or target.read_bytes() != content)):
            raise RuntimeError("Existing destination differs: " + str(target))
    if args.check_only:
        print("CHECK PASSED: archive + 5 media hashes; 6 safe entries. No files written.")
        return
    destination.mkdir(parents=True, exist_ok=True)
    for name, content in payload.items():
        target = destination / name
        if not target.exists():
            target.write_bytes(content)
    print("RESTORED: " + str(destination))
    print("6 files verified. Originals, gameplay and existing walk files were not changed.")
    print("MOVEMENT APPROVED; APPEARANCE PENDING. See reference-manifest.json.")

if __name__ == "__main__":
    main()
