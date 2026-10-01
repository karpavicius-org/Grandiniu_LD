#!/usr/bin/env python3
"""Build a platform package from the checked-out Git commit plus tested native binaries."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import zipfile

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--platform',choices=['Windows','Linux','macOS-arm64','macOS-x86_64'],required=True)
a=p.parse_args()
root=Path(__file__).resolve().parents[1]
source=root/'studentui'
commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
ext='.dll' if a.platform=='Windows' else ('.dylib' if a.platform.startswith('macOS') else '.so')
exe_suffix='.exe' if a.platform=='Windows' else ''
native=['ldcore'+ext,'ldcheck'+exe_suffix,'mokytojas'+exe_suffix]
for name in native:
    assert (source/'bin'/name).is_file(), f'Missing tested binary: {name}'

def tracked(prefix):
    raw=subprocess.check_output(['git','ls-files','-s','-z',prefix],cwd=root)
    for record in raw.decode('utf-8').split('\0'):
        if not record: continue
        meta,name=record.split('\t',1)
        mode=meta.split()[0]
        yield name, int(mode,8)

def git_bytes(name):
    return subprocess.check_output(['git','show',f'HEAD:{name}'],cwd=root)

def add_bytes(z,arc,data,mode=0o100644):
    info=zipfile.ZipInfo(arc,date_time=(1980,1,1,0,0,0))
    info.create_system=3
    info.external_attr=(mode & 0xFFFF)<<16
    info.compress_type=zipfile.ZIP_DEFLATED
    z.writestr(info,data)

dest=root/'dist'/f'Grandiniu_LD-{a.platform}.zip'
dest.parent.mkdir(exist_ok=True)
binary_hashes={}
with zipfile.ZipFile(dest,'w') as z:
    for name,mode in sorted(tracked('studentui'),key=lambda x:x[0]):
        rel=Path(name).relative_to('studentui')
        if 'bin' in rel.parts or 'results' in rel.parts or '__pycache__' in rel.parts: continue
        if rel.suffix in {'.sod','.html','.pyc'}: continue
        add_bytes(z,'Grandiniu_LD/'+rel.as_posix(),git_bytes(name),mode)
    for name,mode in sorted(tracked('core/third_party'),key=lambda x:x[0]):
        rel=Path(name).relative_to('core/third_party')
        add_bytes(z,'Grandiniu_LD/third_party/'+rel.as_posix(),git_bytes(name),mode)
    for name in native:
        data=(source/'bin'/name).read_bytes()
        binary_hashes[name]=hashlib.sha256(data).hexdigest()
        add_bytes(z,'Grandiniu_LD/bin/'+name,data,0o100755)
    release={
        'schema_version':1,
        'source_commit':commit,
        'platform':a.platform,
        'labs':[f'LD{k}' for k in range(1,13)],
        'binaries_sha256':binary_hashes,
    }
    add_bytes(z,'Grandiniu_LD/RELEASE.json',(json.dumps(release,indent=2,ensure_ascii=False)+'\n').encode('utf-8'))

with zipfile.ZipFile(dest) as z:
    assert z.testzip() is None
    names=set(z.namelist())
    required={'Grandiniu_LD/STENDAS.sce','Grandiniu_LD/README.md','Grandiniu_LD/RELEASE.json',
              'Grandiniu_LD/PALEISTI.bat','Grandiniu_LD/PALEISTI.sh','Grandiniu_LD/PALEISTI.command'}
    required|={f'Grandiniu_LD/LD{k}/VARIANTAI.csv' for k in range(1,13)}
    required|={f'Grandiniu_LD/bin/{name}' for name in native}
    missing=required-names
    assert not missing, f'Missing package entries: {sorted(missing)}'
    packaged=json.loads(z.read('Grandiniu_LD/RELEASE.json'))
    assert packaged['source_commit']==commit and packaged['platform']==a.platform
print(f'PASS: {dest} built from {commit} with 12 variant tables and verified release manifest')
