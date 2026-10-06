"""Internal feedback: real LD1 student GUI, native grading and pixel geometry."""
import argparse
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--scilab',type=Path,required=True)
p.add_argument('--checker',type=Path,required=True)
p.add_argument('--grader',type=Path,required=True)
p.add_argument('--output',type=Path,required=True)
a=p.parse_args(); repo=Path(__file__).resolve().parents[1]; out=a.output.resolve(); out.mkdir(parents=True)
runtime=out/'Studento stendas Žąsė'
shutil.copytree(repo/'studentui',runtime,ignore=shutil.ignore_patterns('results','__pycache__','*.html','*.sod'))
(runtime/'tests/results').mkdir(parents=True)
env=dict(os.environ,LD1_TEST_RUNTIME=runtime.as_posix(),LD1_TEST_OUT=out.as_posix(),LD1_TEST_SOURCE=repo.as_posix(),LD_DATA_DIR=(out/'Ataskaitos').as_posix())
env['LD1_CAPTURE_WINDOWS']='1' if importlib.util.find_spec('PIL') else '0'
exe=a.scilab.resolve(); flags=['-nw']
if os.name=='nt': exe=exe.parent/'WScilex.exe'; flags=[]
with (out/'scilab.log').open('wb') as log:
    run=subprocess.run([str(exe),*flags,'-nb','-f',str(repo/'tools/test_ld1_student.sce')],env=env,stdout=log,stderr=subprocess.STDOUT,timeout=360)
verdict=(out/'verdict.log').read_text(encoding='utf-8') if (out/'verdict.log').exists() else (out/'scilab.log').read_text(encoding='utf-8',errors='replace')
assert run.returncode==0 and verdict.startswith('PASS:'),verdict
print(verdict)
geometry=subprocess.run([str(a.checker.resolve()),str(out/'geometry.tsv')],capture_output=True,text=True)
(out/'geometry.log').write_text(geometry.stdout+geometry.stderr,encoding='utf-8');print(geometry.stdout)
assert geometry.returncode==0
sys.path.insert(0,str(repo/'core/tests')); from test_grading import write,run as grade
reports=out/'grading-input'; reports.mkdir()
actual=list((out/'Ataskaitos').glob('*.html')); assert len(actual)==4
for f in actual: shutil.copy2(f,reports/f.name)
for f in out.glob('wrong-*.json'): write(reports/(f.stem+'.html'),json.loads(f.read_text(encoding='utf-8')))
graded,_=grade(a.grader.resolve(),reports,out/'grading-output')
assert len(graded['results'])==7
for result in graded['results']:
    maximum=15 if result['rubric_version']=='LD1-2' else 22
    expected=maximum-1 if result['file'].startswith('wrong-') else maximum
    assert result['status']=='graded' and (result['points'],result['max_points'])==(expected,maximum),result
summary=dict(status='PASS',platform=os.name,gui_variants=[1,17,64],gui_stages=9,geometry_cases=9,client_size=[1280,720],fixed_window=True,actual_reports=4,incorrect_answers_preserved=3,manual_regression=True,os_mouse_injection=False)
(out/'acceptance.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8');print(json.dumps(summary))
