#!/usr/bin/env python3
"""Execute actual Scilab exporters and independently verify C++ verdicts."""
import argparse
from collections import Counter
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time

p=argparse.ArgumentParser()
p.add_argument('--scilab',required=True)
p.add_argument('--runtime',type=Path,required=True)
p.add_argument('--core',type=Path)
p.add_argument('--evidence',type=Path)
a=p.parse_args()
runtime=a.runtime.resolve()
with tempfile.TemporaryDirectory(prefix='LD ataskaitos Žąsė ') as temp:
    env=os.environ.copy();env['LD_DATA_DIR']=temp
    if a.core:env['LD_CORE_LIBRARY']=str(a.core.resolve())
    start=time.monotonic()
    headless=[] if os.name=='nt' else ['-nwni']  # Scilex.exe is already windowless; -nwni unsupported there
    result=subprocess.run([a.scilab,*headless,'-nb','-f',str(runtime/'tests/AUTOMATINIS.sce')],
                          env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=300)
    log=result.stdout.decode('utf-8',errors='replace')
    assert result.returncode==0 and 'AUTOMATIC_PASS:' in log,log
    data=json.loads((Path(temp)/'CFFI-vertinimas/vertinimai.json').read_text(encoding='utf-8'))
    counts=Counter((r['lab_id'],r['points'],r['max_points']) for r in data['results'])
    assert counts==Counter({('LD1',22,22):64,('LD2',50,50):64,('LD3',15,15):64,('LD4',27,27):64,('LD5',16,16):64,('LD6',15,15):64,('LD7',27,27):64,('LD8',21,21):64,('LD9',28,28):64,('LD10',28,28):64,('LD11',20,20):64,('LD12',14,14):64,('LD2',48,50):1}),counts
    evidence=dict(status='PASS',platform=os.name,actual_exported_reports=769,
                  ld1_full_variants=64,ld2_full_variants=64,ld3_full_variants=64,ld4_full_variants=64,ld5_full_variants=64,ld6_full_variants=64,ld7_full_variants=64,ld8_full_variants=64,ld9_full_variants=64,ld10_full_variants=64,ld11_full_variants=64,ld12_full_variants=64,wrong_and_missing_preserved=True,
                  seconds=round(time.monotonic()-start,3),cffi_folder_grading=True)
    if a.evidence:a.evidence.write_text(json.dumps(evidence,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(evidence))
