"""Internal feedback: twelve consistent windows, compact screens and report actions."""
import argparse,json,os,shutil,subprocess,sys
from pathlib import Path
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--scilab',required=True,type=Path);p.add_argument('--grader',required=True,type=Path);p.add_argument('--output',required=True,type=Path)
a=p.parse_args();repo=Path(__file__).resolve().parents[1];out=a.output.resolve();out.mkdir(parents=True)
runtime=out/'Stendas Žąsė'
shutil.copytree(repo/'studentui',runtime,ignore=shutil.ignore_patterns('results','*.html','*.sod','__pycache__'))
(runtime/'tests/results').mkdir(parents=True)
env=dict(os.environ,DELIVERY_ROOT=runtime.as_posix(),DELIVERY_OUT=out.as_posix(),LD_DATA_DIR=(out/'Ataskaitos').as_posix())
exe=a.scilab.resolve();flags=['-nw']
if os.name=='nt':exe=exe.parent/'WScilex-cli.exe';flags=[]
with (out/'scilab.log').open('wb') as log:
    r=subprocess.run([str(exe),*flags,'-nb','-f',str(repo/'tools/test_student_delivery.sce')],env=env,stdout=log,stderr=subprocess.STDOUT,timeout=360)
verdict=(out/'verdict.log').read_text(encoding="utf-8") if (out/'verdict.log').exists() else (out/'scilab.log').read_text(encoding="utf-8",errors='replace')
assert r.returncode==0 and verdict.startswith('PASS:'),verdict
sys.path.insert(0,str(repo/'core/tests'));from test_grading import run
reports,_=run(a.grader.resolve(),out/'Ataskaitos',out/'Vertinimai')
graded=[r for r in reports['results'] if r['status']=='graded'];assert len(graded)==2
assert all(r['points']==r['max_points'] for r in graded),graded
ld3=next(r for r in graded if r['lab_id']=='LD3')
assert ld3['mode']=='assessment' and ld3['selected_for_summary'] and not ld3['practice_used'],ld3
summary=dict(status='PASS',platform=sys.platform,labs=list(range(1,13)),canvases=dict(LD1=[1280,640],other_labs=[1280,720]),small_screens=[[1024,768],[900,600]],scrollable=True,report_buttons=3,ld2_ld3_workflows=True)
(out/'acceptance.json').write_text(json.dumps(summary,indent=2)+'\n');print(verdict);print(json.dumps(summary))
