"""Reconstruct the exact Flow walk test from repository transfer parts."""
import base64, hashlib
from pathlib import Path
PARTS = ["part-000.b64","part-001.b64","part-002.b64","part-003.b64","part-004.b64","part-005.b64","part-006.b64","part-007.b64","part-008.b64","part-009.b64","part-010.b64","part-011.b64","part-012.b64","part-013.b64","part-014.b64","part-015.b64","part-016.b64","part-017.b64","part-018.b64"]
EXPECTED = "7c644df616db66b7a3bd7747ddf27f65479e156cf2a869bd11598f74e8794011"
SIZE = 3695350
def main():
    root = Path(__file__).resolve().parent
    folder = root / "artifacts/sound-clash/art-source/feedback/walk-video-transfer"
    data = b"".join(base64.b64decode((folder / name).read_text().strip(), validate=True) for name in PARTS)
    if len(data) != SIZE or hashlib.sha256(data).hexdigest() != EXPECTED:
        raise SystemExit("Video checksum mismatch; nothing written")
    target = root / "artifacts/sound-clash/art-source/feedback/feedback-walk-flow-test.mp4"
    if target.exists() and target.read_bytes() != data:
        raise SystemExit("Different video exists; preserve it")
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(data)
    print("Verified original walk test:", target)
    print("SHA256:", EXPECTED)
if __name__ == "__main__":
    main()
