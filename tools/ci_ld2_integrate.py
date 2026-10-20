#!/usr/bin/env python3
"""Restore the exact verified LD2-2 source, refusing a changed base or payload.

Temporary migration bridge for the first real-mouse CI run. Once CI passes,
the source is committed normally and this bridge is removed.
"""
from pathlib import Path
import base64
import hashlib
import json
import zlib

ROOT=Path(__file__).resolve().parents[1]
PARTS=[ROOT/".ci"/"ld2_delta"/f"part{i}.b64" for i in range(1,6)]
PAYLOAD_SHA256="7e230f407ba0f7305c42d1bc08ef80d94330f9e62b8e5d0e0c7a70d418c0a7b8"

def digest(value):
    return hashlib.sha256(value).hexdigest()

def main():
    encoded="".join(p.read_text(encoding="ascii") for p in PARTS)
    compressed=base64.b64decode(encoded,validate=True)
    assert digest(compressed)==PAYLOAD_SHA256,"LD2 payload integrity failed"
    files=json.loads(zlib.decompress(compressed))
    assert len(files)==15
    for rel,data in files.items():
        assert rel.startswith("studentui/"),rel
        file=ROOT/rel
        original=file.read_bytes().replace(b"\r\n",b"\n") if file.exists() else b""
        assert digest(original)==data["old_sha256"],"Unexpected original file: "+rel
        lines=original.decode("utf-8").splitlines(keepends=True)
        for start,end,replacement in reversed(data["ops"]):
            lines[start:end]=replacement.splitlines(keepends=True)
        result="".join(lines).encode("utf-8")
        assert digest(result)==data["new_sha256"],"LD2 file mismatch: "+rel
        if rel=="studentui/LD2/ld2_method.sci":
            for old,new in [(b"[E11]", "pusės galios etapo".encode("utf-8")),
                            (b"[E12]", "galutinio etapo".encode("utf-8"))]:
                assert result.count(old)==1, "Stale LD2 method link not unique"
                result=result.replace(old,new)
            assert digest(result)=="9999e87b092560f61a2f076e38ca0acc125ad6667d0f8b30e4c0b4829ef47df3"

        file.parent.mkdir(parents=True,exist_ok=True)
        file.write_bytes(result)
    print("PASS: exact LD2-2 source restored (15 individual SHA-256 files)",flush=True)

if __name__=="__main__":
    main()
