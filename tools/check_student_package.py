#!/usr/bin/env python3
"""Verify the combined classroom ZIP against the current Git commit and release manifest."""
import hashlib
import json
from pathlib import Path
import subprocess
import zipfile

root=Path(__file__).resolve().parents[1]
student=root/'studentui'
commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
prefix='Grandiniu_LD-studentui/'
archive_path=root/'dist/Grandiniu_LD-studentui.zip'

def git_bytes(name):
    return subprocess.check_output(['git','show',f'HEAD:{name}'],cwd=root)

def tracked_runtime():
    raw=subprocess.check_output(['git','ls-files','-z','studentui'],cwd=root).decode('utf-8')
    result=[]
    for name in filter(None,raw.split('\0')):
        rel=Path(name).relative_to('studentui')
        if 'results' in rel.parts or 'bin' in rel.parts: continue
        if rel.suffix in {'.sci','.sce','.sh','.bat','.command'}: result.append((name,rel.as_posix()))
    return sorted(result)

with zipfile.ZipFile(archive_path) as archive:
    assert archive.testzip() is None,'Corrupt ZIP entry'
    release=json.loads(archive.read(prefix+'RELEASE.json'))
    assert release['source_commit']==commit,(release['source_commit'],commit)
    assert release['labs']==[f'LD{k}' for k in range(1,13)]
    for name,rel in tracked_runtime():
        expected=git_bytes(name)
        assert archive.read(prefix+rel)==expected,f'Missing or outdated ZIP source: {rel}'
    for rel in ['README.md','capture_window.py',*[f'LD{k}/VARIANTAI.csv' for k in range(1,13)]]:
        expected=git_bytes('studentui/'+rel)
        assert archive.read(prefix+rel)==expected,rel
    for key,digest in release['binaries_sha256'].items():
        name=key.split('/',1)[1]
        assert hashlib.sha256(archive.read(prefix+'bin/'+name)).hexdigest()==digest,key
    for rel in ['PALEISTI.sh','PALEISTI.command','PATIKRINTI.sh']:
        assert (archive.getinfo(prefix+rel).external_attr>>16)&0o111,rel

print(f'PASS: combined ZIP matches {commit}; 12 variant tables, runtime sources, executable launchers and native SHA256 verified')
