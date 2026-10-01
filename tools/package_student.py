#!/usr/bin/env python3
"""Combine matching Windows/Linux CI packages from one source commit."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import zipfile

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--windows',type=Path,required=True)
p.add_argument('--linux',type=Path,required=True)
a=p.parse_args()
root=Path(__file__).resolve().parents[1]
student=root/'studentui'
commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
prefix='Grandiniu_LD-studentui/'

def git_bytes(name):
    return subprocess.check_output(['git','show',f'HEAD:{name}'],cwd=root)

def tracked(prefix_path):
    raw=subprocess.check_output(['git','ls-files','-s','-z',prefix_path],cwd=root)
    for record in raw.decode('utf-8').split('\0'):
        if not record: continue
        meta,name=record.split('\t',1)
        yield name,int(meta.split()[0],8)

def add_bytes(z,arc,data,mode=0o100644):
    info=zipfile.ZipInfo(arc,date_time=(1980,1,1,0,0,0))
    info.create_system=3
    info.external_attr=(mode & 0xFFFF)<<16
    info.compress_type=zipfile.ZIP_DEFLATED
    z.writestr(info,data)

platforms=[('Windows',a.windows,['ldcore.dll','ldcheck.exe','mokytojas.exe']),
           ('Linux',a.linux,['ldcore.so','ldcheck','mokytojas'])]
releases={}
for platform,path,_ in platforms:
    with zipfile.ZipFile(path) as z:
        release=json.loads(z.read('Grandiniu_LD/RELEASE.json'))
        assert release['source_commit']==commit, f'{platform}: package commit {release["source_commit"]} != {commit}'
        assert release['platform']==platform, f'{platform}: wrong platform manifest'
        releases[platform]=release

destination=root/'dist/Grandiniu_LD-studentui.zip'
destination.parent.mkdir(exist_ok=True)
pending=destination.with_suffix('.zip.tmp')
combined_hashes={}
with zipfile.ZipFile(pending,'w') as out:
    for name,mode in sorted(tracked('studentui'),key=lambda x:x[0]):
        rel=Path(name).relative_to('studentui')
        if 'bin' in rel.parts or 'results' in rel.parts or '__pycache__' in rel.parts: continue
        if rel.suffix in {'.html','.sod','.log','.pyc'}: continue
        add_bytes(out,prefix+rel.as_posix(),git_bytes(name),mode)
    for name,mode in sorted(tracked('core/third_party'),key=lambda x:x[0]):
        rel=Path(name).relative_to('core/third_party')
        add_bytes(out,prefix+'third_party/'+rel.as_posix(),git_bytes(name),mode)
    for platform,path,binaries in platforms:
        with zipfile.ZipFile(path) as source:
            for name in binaries:
                arc='Grandiniu_LD/bin/'+name
                data=source.read(arc)
                digest=hashlib.sha256(data).hexdigest()
                assert releases[platform]['binaries_sha256'][name]==digest
                combined_hashes[f'{platform}/{name}']=digest
                old=source.getinfo(arc)
                mode=(old.external_attr>>16) or 0o100755
                add_bytes(out,prefix+'bin/'+name,data,mode)
    release={'schema_version':1,'source_commit':commit,'platforms':['Windows','Linux'],
             'labs':[f'LD{k}' for k in range(1,13)],'binaries_sha256':combined_hashes}
    add_bytes(out,prefix+'RELEASE.json',(json.dumps(release,indent=2,ensure_ascii=False)+'\n').encode('utf-8'))

pending.replace(destination)
with zipfile.ZipFile(destination) as z:
    assert z.testzip() is None
    names=set(z.namelist())
    required={prefix+'STENDAS.sce',prefix+'README.md',prefix+'RELEASE.json'}
    required|={prefix+f'LD{k}/VARIANTAI.csv' for k in range(1,13)}
    assert required<=names, sorted(required-names)
print(f'PASS: combined package uses Windows/Linux artifacts from {commit} and includes all 12 variant tables')
