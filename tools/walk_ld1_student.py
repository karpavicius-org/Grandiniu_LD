"""Walk LD1 through real Windows mouse actions; capture the student's screens and report."""
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

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--scilab',type=Path,required=True)
p.add_argument('--output',type=Path,required=True)
p.add_argument('--runtime',type=Path)
a=p.parse_args()
assert os.name=='nt'
repo=Path(__file__).resolve().parents[1]; out=a.output.resolve(); out.mkdir(parents=True)
runtime=(a.runtime or repo/'studentui').resolve()
scihome=out/'scihome'; scihome.mkdir()
env=dict(os.environ,LD1_WALK_RUNTIME=runtime.as_posix(),LD1_WALK_SOURCE=repo.as_posix(),LD1_WALK_OUT=out.as_posix(),LD_DATA_DIR=(out/'Ataskaitos').as_posix())
user=c.windll.user32; user.SetProcessDPIAware()
process=subprocess.Popen([str(a.scilab.resolve().parent/'WScilex.exe'),'-nb','-scihome',str(scihome),'-f',str(repo/'tools/walk_ld1_student.sce')],env=env)
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
    found=[]
    @c.WINFUNCTYPE(w.BOOL,w.HWND,w.LPARAM)
    def visit(hwnd,_):
        title=c.create_unicode_buffer(512); user.GetWindowTextW(hwnd,title,len(title))
        owner=w.DWORD(); user.GetWindowThreadProcessId(hwnd,c.byref(owner))
        if owner.value==process.pid and title.value.startswith('LD1') and user.IsWindowVisible(hwnd): found.append(hwnd)
        return True
    user.EnumWindows(visit,0); assert len(found)==1,found
    return found[0]

def click(tag):
    before=read_state(); hwnd=find_window(); user.SetForegroundWindow(hwnd)
    rows=[line.split('\t') for line in (out/'geometry.tsv').read_text(encoding='utf-8').splitlines()]
    row=next((row for row in rows if row[3]==tag),None)
    assert row is not None,f'Visible control missing at stage {before["step"]}: {tag}'
    x,y,width,height=map(float,row[4:8])
    rect=w.RECT(); user.GetClientRect(hwnd,c.byref(rect)); origin=w.POINT(0,0); user.ClientToScreen(hwnd,c.byref(origin))
    point=(round(origin.x+x+width/2),round(origin.y+rect.bottom-y-height/2))
    assert origin.x<=point[0]<origin.x+rect.right and origin.y<=point[1]<origin.y+rect.bottom,(tag,point)
    actions.append(dict(stage=before['step'],control=tag,point=point))
    # Allow Swing to finish the redraw and receive the cursor movement before pressing.
    time.sleep(.4); user.SetCursorPos(*point); time.sleep(.15)
    user.mouse_event(2,0,0,0,0); time.sleep(.08); user.mouse_event(4,0,0,0,0)
    time.sleep(.3); state=read_state(before['sequence'],30)
    (out/'actions.json').write_text(json.dumps(actions,indent=2),encoding='utf-8')
    return state

def screenshot(stage):
    from PIL import ImageGrab
    hwnd=find_window(); user.SetForegroundWindow(hwnd); time.sleep(.3)
    rect=w.RECT(); user.GetWindowRect(hwnd,c.byref(rect))
    name=f'E{stage}.png'; ImageGrab.grab(bbox=(rect.left,rect.top,rect.right,rect.bottom)).save(out/name); screens.append(name)

def wire(pairs):
    for first,second in pairs: click(first); click(second)

def close(actual,expected):
    assert actual is not None and math.isclose(actual,expected,rel_tol=1e-8,abs_tol=1e-8),(actual,expected)

def numbers(state,expected):
    values=state['numbers']
    if isinstance(values[0],list): values=values[0]
    for value,wanted in zip(values,expected):
        assert abs(float(value.replace(',','.'))-wanted)<=.00051,(value,wanted)

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
    click('choice-yes'); state=click('B14'); assert state['step']==5 and not state['power'] and state['mode']=='V'; screenshot(5)
    assert not any(state['choice'][:3]),state
    wire([('T01','T13'),('T02','T17'),('T14','T07'),('T08','T18'),('T15','T05'),('T06','T09'),('T10','T19'),('T11','T16'),('T12','T20')])
    click('choice-type-2'); state=click('B14'); assert state['step']==6
    state=click('B06'); close(state['measurement'],cfg['E']); numbers(state,[cfg['R3']*(cfg['R2']+1000)/(cfg['R3']+cfg['R2']+1000)]); screenshot(6)
    click('choice-yes'); state=click('B14'); assert state['step']==7
    state=click('B03'); assert state['VR']==500; close(state['measurement'],cfg['E']); screenshot(7)
    click('choice-no'); state=click('B14'); assert state['step']==8 and not state['power'] and state['mode']=='A' and state['VR']==0
    assert not any(state['choice'][3:]),state
    target={'NODE_A1':'T13','NODE_A2':'T14','NODE_A3':'T15','NODE_A4':'T16'}[state['target']]
    wire([('T01','T11'),('T12',target)])
    state=click('B06'); expected=[1000*cfg['E']/cfg['R3'],1000*cfg['E']/cfg['R2']]
    numbers(state,expected+[sum(expected)]); close(state['measurement'],sum(expected)); screenshot(8)
    # Power off preserves saved readings and the controls remain usable on return.
    measured=state['measurement']; state=click('B01'); assert not state['power']; close(state['measurement'],measured)
    click('choice-yes'); state=click('B14'); assert state['step']==9; screenshot(9)
    state=click('B15'); assert state['step']==8; close(state['measurement'],measured)
    state=click('B14'); assert state['step']==9
    click('B14'); reports=list((out/'Ataskaitos').glob('*.html')); assert len(reports)==1,reports
    content=reports[0].read_text(encoding='utf-8'); assert 'automatic_calculation' in content and 'Skaitines reikšmes apskaičiuoja' in content
    result=dict(status='PASS',actual_mouse_actions=len(actions),manual_wires=15,manual_numeric_entries=0,measure_actions=[2,6,8],automatic_measurement_stages=[3,4,7],screens=screens,report=str(reports[0]))
    (out/'acceptance.json').write_text(json.dumps(result,indent=2,ensure_ascii=False)+'\n',encoding='utf-8'); print(json.dumps(result,ensure_ascii=False))
finally:
    if process.poll() is None:
        try: screenshot('last')
        except Exception: pass
    if process.poll() is None: process.terminate(); process.wait(timeout=10)
