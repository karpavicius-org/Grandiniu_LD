"""Verify Windows LD1 power and Measure with actual desktop mouse events."""
import argparse
import ctypes as c
from ctypes import wintypes as w
import json
import math
import os
from pathlib import Path
import subprocess
import time

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--scilab',type=Path,required=True)
p.add_argument('--output',type=Path,required=True)
a=p.parse_args()
assert os.name=='nt','This smoke test uses the Windows desktop.'
repo=Path(__file__).resolve().parents[1]; out=a.output.resolve(); out.mkdir(parents=True)
env=dict(os.environ,LD1_MOUSE_SOURCE=repo.as_posix(),LD1_MOUSE_OUT=out.as_posix(),LD_DATA_DIR=(out/'Ataskaitos').as_posix())
user=c.windll.user32; user.SetProcessDPIAware()
process=subprocess.Popen([str(a.scilab.resolve().parent/'WScilex.exe'),'-nb','-f',str(repo/'tools/test_ld1_mouse.sce')],env=env)

def await_file(name,timeout=120):
    deadline=time.monotonic()+timeout
    while not (out/name).exists():
        if (out/'failure').exists(): raise AssertionError((out/'failure').read_text(encoding='utf-8'))
        assert process.poll() is None,'Scilab exited before the desktop check.'
        assert time.monotonic()<deadline,f'Timeout: {name}'
        time.sleep(.2)

try:
    await_file('ready')
    windows=[]
    @c.WINFUNCTYPE(w.BOOL,w.HWND,w.LPARAM)
    def visit(hwnd,_):
        title=c.create_unicode_buffer(512); user.GetWindowTextW(hwnd,title,len(title))
        if title.value=='LD1 · Pelės patikra' and user.IsWindowVisible(hwnd): windows.append(hwnd)
        return True
    user.EnumWindows(visit,0); assert len(windows)==1,windows
    hwnd=windows[0]; user.SetForegroundWindow(hwnd); time.sleep(.5)
    rect=w.RECT(); user.GetClientRect(hwnd,c.byref(rect))
    origin=w.POINT(0,0); user.ClientToScreen(hwnd,c.byref(origin))
    rows=[line.split('\t') for line in (out/'geometry.tsv').read_text(encoding='utf-8').splitlines()]
    for tag in ['B01','B06']:
        row=next(row for row in rows if row[3]==tag and row[2]=='pushbutton')
        x,y,width,height=map(float,row[4:8])
        target=(round(origin.x+x+width/2),round(origin.y+rect.bottom-y-height/2))
        assert origin.y<=target[1]<origin.y+rect.bottom,(tag,target)
        user.SetCursorPos(*target); user.mouse_event(2,0,0,0,0); user.mouse_event(4,0,0,0,0); time.sleep(1)
    await_file('reading.json',30)
    reading=json.loads((out/'reading.json').read_text(encoding='utf-8'))
    assert reading['power'] and math.isclose(reading['measurement'],reading['expected'],rel_tol=1e-8),reading
    try:
        import PIL
    except ImportError:
        pass
    else:
        subprocess.run([os.sys.executable,str(repo/'studentui/capture_window.py'),'LD1 · Atsiskaitymas',str(out/'measured.png')],check=True)
    evidence=dict(status='PASS',actual_mouse_clicks=['source_power','meter_measure'],reading=reading)
    (out/'acceptance.json').write_text(json.dumps(evidence,indent=2)+'\n',encoding='utf-8'); print(json.dumps(evidence))
finally:
    if process.poll() is None: process.terminate(); process.wait(timeout=10)
