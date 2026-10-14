"""Complete LD1 using native Windows/Linux desktop pointer events in real Scilab GUI.

This test never calls a student's Scilab callback or changes laboratory state
directly. The enrollment identity is a fixed test fixture, not OS keyboard input.
"""
import argparse
import ctypes as c
from ctypes import wintypes as w
import json
import math
import os
import re
from pathlib import Path
import subprocess
import time
import sys
from test_ld678_os_input import Desktop

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--scilab',type=Path,required=True)
p.add_argument('--output',type=Path,required=True)
p.add_argument('--core',type=Path,required=True)
p.add_argument('--grader',type=Path,required=True)
p.add_argument('--checker',type=Path,required=True)
p.add_argument('--runtime',type=Path)
a=p.parse_args()
repo=Path(__file__).resolve().parents[1]; out=a.output.resolve(); out.mkdir(parents=True)
runtime=(a.runtime or repo/'studentui').resolve()
scihome=out/'scihome'; scihome.mkdir()
env=dict(os.environ,LD1_WALK_RUNTIME=runtime.as_posix(),LD1_WALK_SOURCE=repo.as_posix(),LD1_WALK_OUT=out.as_posix(),LD_DATA_DIR=(out/'Ataskaitos').as_posix())
desktop=Desktop("LD1",out)
env['LD_CORE_LIBRARY']=str(a.core.resolve())
exe=a.scilab.resolve()
if os.name=='nt': exe=exe.parent/'WScilex.exe'
flags=[] if os.name=='nt' else ['-nw']
command=[str(exe),*flags,'-nb','-scihome',str(scihome),'-f',str(repo/'tools/test_ld1_full_os_input.sce')]
log=(out/'scilab.log').open('wb')
process=subprocess.Popen(command,env=env,stdin=subprocess.PIPE,stdout=log,stderr=subprocess.STDOUT,
                         start_new_session=(os.name!='nt'))
actions=[]; screens=[]

def read_state(after=-1,timeout=90):
    deadline=time.monotonic()+timeout
    while time.monotonic()<deadline:
        if (out/'failure').exists(): raise AssertionError((out/'failure').read_text(encoding='utf-8'))
        assert process.poll() is None,'Scilab exited during the walkthrough.'
        try:
            state=json.loads(re.sub(r'\bnan\b','null',(out/'state.json').read_text(encoding='utf-8')))
        except (FileNotFoundError,json.JSONDecodeError):
            time.sleep(.1); continue
        if state['sequence']>after: return state
        time.sleep(.1)
    raise AssertionError(f'No response after mouse action: {actions[-1:]}')

def find_window():
    if desktop.window is None:
        desktop.locate()
    return desktop.window

def click(tag):
    before=read_state()
    find_window()
    rows=[line.split('\t') for line in (out/'geometry.tsv').read_text(encoding='utf-8').splitlines()]
    matches=[row for row in rows if len(row)>7 and row[3]==tag]
    assert len(matches)==1, f'LD1 stage {before["step"]}: no unique visible control {tag}: {matches}'
    row=matches[0]
    assert row[2] in ('pushbutton','radiobutton'),(tag,row[2])
    x,y,width,height=map(float,row[4:8])
    desktop.update_origin()
    ox,oy=desktop.client_origin
    client_w,client_h=desktop.client_size
    point=(round(ox+x+width/2),round(oy+client_h-y-height/2))
    assert ox<=point[0]<ox+client_w and oy<=point[1]<oy+client_h, (tag,point,desktop.client_size)
    desktop.click_xy(*point)
    state=read_state(before['sequence'],40)
    actions.append(dict(stage=before['step'],control=tag,point=point,
                        next_step=state['step'],seq=state['sequence']))
    (out/'actions.json').write_text(json.dumps(actions,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    return state

def screenshot(stage):
    hwnd=find_window()
    desktop.update_origin()
    target=out/f'E{stage}.png'
    if os.name=='nt':
        from PIL import ImageGrab
        rect=w.RECT()
        assert desktop.user.GetWindowRect(hwnd,c.byref(rect))
        ImageGrab.grab(bbox=(rect.left,rect.top,rect.right,rect.bottom)).save(target)
    else:
        subprocess.run(['/usr/bin/python3',str(repo/'studentui/capture_window.py'),
                        'LD1 · OS INPUT TEST',str(target)],check=True,timeout=20,
                       env=env,stdout=subprocess.DEVNULL)
    screens.append(target.name)

def wire(pairs):
    for first,second in pairs: click(first); click(second)

def close(actual,expected):
    assert actual is not None and math.isclose(actual,expected,rel_tol=1e-8,abs_tol=1e-8),(actual,expected)

def numbers(state,expected):
    values=state['numbers']
    if isinstance(values[0],list): values=values[0]
    assert all(value=='' for value in values),values

try:
    state=read_state(); cfg=state['cfg']; screenshot(1)
    assert not any(state['choice']),state
    # The visible action must reject an incomplete circuit without powering it.
    state=click('B06'); assert not state['power'] and state['measurement'] is None,state
    wire([('T01','T03'),('T04','T09'),('T10','T11'),('T12','T02')])
    click('choice-type-1'); state=click('B14'); assert state['step']==2,state
    numbers(state,[cfg['R1']+1000,1000*cfg['E']/(cfg['R1']+1000)])
    # One action powers and measures; no manual answer transcription.
    state=click('B06'); assert state['power']; close(state['measurement'],1000*cfg['E']/(cfg['R1']+1000)); screenshot(2)
    measured=state['measurement']; state=click('B14'); assert state['step']==3; close(state['measurement'],measured); screenshot(3)
    click('choice-yes'); state=click('B14'); assert state['step']==4
    assert not any(state['choice'][3:]),state
    state=click('B03'); assert state['VR']==500; close(state['measurement'],1000*cfg['E']/(cfg['R1']+500))
    numbers(state,[cfg['R1']+500,1000*cfg['E']/(cfg['R1']+500)]); screenshot(4)
    click('choice-type-1'); state=click('B14'); assert state['step']==5 and not state['power'] and state['mode']=='V'; screenshot(5)
    assert not any(state['choice'][:3]),state
    wire([('T01','T13'),('T02','T17'),('T14','T07'),('T08','T18'),('T15','T05'),('T06','T09'),('T10','T19'),('T11','T16'),('T12','T20')])
    click('choice-type-2'); state=click('B14'); assert state['step']==6
    state=click('B06'); close(state['measurement'],cfg['E']); numbers(state,[cfg['R3']*(cfg['R2']+1000)/(cfg['R3']+cfg['R2']+1000)]); screenshot(6)
    click('choice-yes'); state=click('B14'); assert state['step']==7
    state=click('B03'); assert state['VR']==500; close(state['measurement'],cfg['E']); screenshot(7)
    click('choice-type-3'); state=click('B14'); assert state['step']==8 and not state['power'] and state['mode']=='A' and state['VR']==0
    assert not any(state['choice'][3:]),state
    target={'NODE_A1':'T13','NODE_A2':'T14','NODE_A3':'T15','NODE_A4':'T16'}[state['target']]
    wire([('T01','T11'),('T12',target)])
    state=click('B06'); expected=[1000*cfg['E']/cfg['R3'],1000*cfg['E']/cfg['R2']]
    numbers(state,expected+[sum(expected)]); close(state['measurement'],sum(expected)); screenshot(8)
    # Power off preserves saved readings and the controls remain usable on return.
    measured=state['measurement']; state=click('B06'); assert not state['power']; close(state['measurement'],measured)
    click('choice-yes'); state=click('B14'); assert state['step']==9; screenshot(9)
    state=click('B15'); assert state['step']==8; close(state['measurement'],measured)
    state=click('B14'); assert state['step']==9
    click('B14'); reports=list((out/'Ataskaitos').glob('*.html')); assert len(reports)==1,reports
    content=reports[0].read_text(encoding='utf-8'); assert 'LD1-3' in content and 'virtualiuose matavimo taškuose' in content
    # The native HTML from the clicked workflow must be accepted by the real C++ grader.
    sys.path.insert(0,str(repo/'core/tests'))
    from test_grading import run as grade
    grades,_=grade(a.grader.resolve(),out/'Ataskaitos',out/'grading')
    assert len(grades['results'])==1, grades
    result_grade=grades['results'][0]
    assert result_grade['status']=='graded' and (result_grade['points'],result_grade['max_points'])==(9,9),result_grade
    assert result_grade['rubric_version']=='LD1-3' and result_grade['selected_for_summary'],result_grade
    assert not result_grade['practice_used'] and result_grade['mode']=='assessment',result_grade
    geometry=subprocess.run([str(a.checker.resolve()),str(out/'geometry.tsv')],
                            capture_output=True,text=True)
    (out/'geometry.log').write_text(geometry.stdout+geometry.stderr,encoding='utf-8')
    assert geometry.returncode==0,geometry.stdout+geometry.stderr
    result=dict(status='PASS',native_os=os.name,lab='LD1',variant=17,
                actual_mouse_actions=len(actions),all_stages=9,manual_wires=15,
                manual_numeric_entries=0,test_enrollment_fixture=True,
                measure_actions=[2,6,8],automatic_measurement_stages=[3,4,7],
                screens=screens,report=reports[0].name,
                grader=dict(points=result_grade['points'],max_points=result_grade['max_points'],
                            rubric=result_grade['rubric_version']),
                input_method='native Windows user32 / Linux X11 mouse events; no callback injection')
    (out/'acceptance.json').write_text(json.dumps(result,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    print('LD1_NATIVE_FULL_PASS: '+json.dumps(result,ensure_ascii=False),flush=True)
except Exception as exc:
    (out/'failure.txt').write_text(type(exc).__name__+': '+str(exc)+'\n',encoding='utf-8')
    if process.poll() is None:
        try: screenshot('last')
        except Exception: pass
    raise
finally:
    if process.poll() is None:
        try:
            if process.stdin:
                process.stdin.write(b'exit(0)\n'); process.stdin.flush()
                process.wait(timeout=5)
        except (OSError,subprocess.TimeoutExpired): pass
    if process.poll() is None:
        process.terminate()
        try: process.wait(timeout=12)
        except subprocess.TimeoutExpired:
            process.kill(); process.wait(timeout=5)
    log.close()
