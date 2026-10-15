#!/usr/bin/env python3
"""LD3 six-stage OS pointer/keyboard acceptance; no callback injection.
Test identity is fixed. Measurements come only from genuine GUI interactions.
The analytic 64-variant tests are explicitly synthetic, not physical tests.
"""
import argparse
import ctypes
import json
import math
import os
from pathlib import Path
import re
import subprocess
import sys
import time
from test_ld678_os_input import Desktop

ROOT = Path(__file__).resolve().parents[1]
WIRES = [('T01','T03'),('T04','T05'),('T06','T07'),('T08','T02'),('T09','T07'),('T10','T08')]

def flat(x):
    return sum((flat(v) for v in x), []) if isinstance(x,list) else [x]

def read_json(path):
    return json.loads(re.sub(r'\bnan\b','null',path.read_text(encoding='utf-8')))

class NativeLD3:
    def __init__(self,args):
        self.args=args; self.out=args.output.resolve(); self.out.mkdir(parents=True,exist_ok=True)
        self.desktop=Desktop('LD3',self.out); self.events=[]; self.seq=-1; self.proc=None; self.shots=[]
        self.env=dict(os.environ,LD3_NATIVE_ROOT=ROOT.as_posix(),LD3_NATIVE_OUT=self.out.as_posix(),
                      LD_DATA_DIR=(self.out/'reports').as_posix(),LD_CORE_LIBRARY=str(args.core.resolve()))
    def wait(self,after,event,seconds=25):
        end=time.monotonic()+seconds; state=None
        while time.monotonic()<end:
            if (self.out/'failure').exists():
                raise RuntimeError((self.out/'failure').read_text(encoding='utf-8'))
            try:
                state=read_json(self.out/'state.json')
                if state['seq']>after and state['event']==event:
                    self.state=state; self.seq=state['seq'];return state
            except (ValueError,OSError,KeyError):pass
            if self.proc.poll() is not None:raise RuntimeError('Scilab exited: '+str(self.proc.returncode))
            time.sleep(.08)
        raise TimeoutError(f'Expected {event} after {after}, last={state}, actions={self.events[-3:]}')
    def start(self):
        (self.out/'scihome').mkdir(exist_ok=True)
        exe=self.args.scilab.resolve()
        if os.name=='nt':exe=exe.parent/'WScilex.exe'
        cmd=[str(exe)]+([] if os.name=='nt' else ['-nw'])+['-nb','-scihome',str(self.out/'scihome'),'-f',str(ROOT/'tools/test_ld3_native.sce')]
        self.log=(self.out/'scilab.log').open('wb')
        self.proc=subprocess.Popen(cmd,env=self.env,stdin=subprocess.PIPE,stdout=self.log,stderr=subprocess.STDOUT,start_new_session=os.name!='nt')
        s=self.wait(-1,'ready',90);self.desktop.locate();self.cfg=s['cfg']
        assert s['step']==1 and s['done_count']==0 and s['wire_count']==0,s
        assert self.cfg==dict(R=56,U1=3,U2=6,U3=9),self.cfg
    def point(self,tag,style):
        rows=[r.split('\t') for r in (self.out/'geometry.tsv').read_text(encoding='utf-8').splitlines()]
        rows=[r for r in rows if len(r)==13 and r[3]==tag and r[2]==style]
        assert len(rows)==1,(tag,rows,self.state['step'])
        x,y,w,h=map(float,rows[0][4:8]);self.desktop.update_origin()
        ox,oy=self.desktop.client_origin;cw,ch=self.desktop.client_size
        pt=(round(ox+x+w/2),round(oy+ch-y-h/2))
        assert ox<=pt[0]<ox+cw and oy<=pt[1]<oy+ch,(tag,pt,(cw,ch))
        return pt
    def record(self,kind,**fields):
        self.events.append(dict(kind=kind,**fields))
        (self.out/'actions.json').write_text(json.dumps(self.events,ensure_ascii=False,indent=2),encoding='utf-8')
    def click(self,tag,event):
        before=self.seq;pt=self.point(tag,'pushbutton');self.desktop.click_xy(*pt)
        s=self.wait(before,event);self.record('mouse',tag=tag,point=pt,step=s['step']);return s
    def enter(self,step,slot,text):
        text=str(text);tag=f'A{step:02d}.{slot:02d}';before=self.seq;pt=self.point(tag,'edit')
        self.desktop.click_xy(*pt);self.desktop.key('ctrl+a')
        if os.name=='nt':self.desktop.type_text(text)
        else:subprocess.run(['xdotool','type','--clearmodifiers','--delay','8','--',text],check=True)
        self.desktop.key('Tab');s=self.wait(before,'answer')
        assert flat(s['answers'])[slot-1]==text,(tag,text,s['answers'])
        self.record('keyboard',tag=tag,text=text)
    def advance(self,step,done):
        s=self.click('OS_PRIMARY','primary');assert (s['step'],s['done_count'])==(step,done),s;return s
    def snap(self,name):
        rows=(self.out/'geometry.tsv').read_text(encoding='utf-8').splitlines()
        with (self.out/'geometry_all.tsv').open('a',encoding='utf-8') as f:
            for r in rows:
                parts=r.split('\t');assert len(parts)==13,parts
                parts[0]=name;f.write('\t'.join(parts)+'\n')
        self.desktop.update_origin();x,y=self.desktop.client_origin;w,h=self.desktop.client_size
        target=self.out/(name+'.png')
        if os.name=='nt':
            from PIL import ImageGrab
            ImageGrab.grab(bbox=(x,y,x+w,y+h)).save(target)
        else:
            code='import gi,sys;gi.require_version("Gdk","3.0");from gi.repository import Gdk; r=Gdk.get_default_root_window();p=Gdk.pixbuf_get_from_window(r,*map(int,sys.argv[2:]));assert p is not None;p.savev(sys.argv[1],"png",[],[])'
            subprocess.run(['/usr/bin/python3','-c',code,str(target),str(x),str(y),str(w),str(h)],check=True,env=self.env,timeout=20)
        self.shots.append(target.name)
    def journal(self):
        j=self.state['journal'];assert len(j)==3 and all(len(row)==2 for row in j),j
        for (u,i),want in zip(j,[3,6,9]):
            assert u==want and math.isclose(i,1000*want/56,rel_tol=1e-12),(u,i)
        return j
    def work(self):
        self.snap('E01');self.advance(1,0) # cannot skip incomplete wiring
        self.click('T01','terminal');s=self.click('T01','terminal')
        assert s['pending']=='' and s['wire_count']==0,s # cancel first endpoint
        for n,(a,b) in enumerate(WIRES,1):
            self.click(a,'terminal');s=self.click(b,'terminal');assert s['wire_count']==n,s
        self.advance(2,1);self.advance(2,1) # missing answer rejected
        self.enter(2,1,'1+2');self.advance(2,1)
        assert 'skai' in self.state['status'].lower(),self.state
        self.enter(2,1,f'{3000/56:.10f}'.replace('.',','))
        s=self.click('B03','measure');assert s['journal_count']==0,s # unpowered measurement
        self.click('B10','voltage');self.click('B01','power')
        s=self.click('B03','measure');assert s['journal_count']==0,s # open switch
        self.click('B02','switch');s=self.click('B03','measure');assert s['journal_count']==1,s
        s=self.click('B03','measure');assert s['journal_count']==1,s # duplicate must not add point
        self.snap('E02')
        # Assessment records a valid but wrong number without exposing solutions.
        self.enter(2,1,'999');self.advance(3,2)
        assert '999' in flat(self.state['all_answers']),self.state
        self.click('OS_BACK','back');assert self.state['step']==2
        self.enter(2,1,f'{3000/56:.10f}');self.advance(3,2)
        for k in [2,3]:
            self.click('B'+str(9+k),'voltage');s=self.click('B03','measure');assert s['journal_count']==k,s
        j=self.journal();self.snap('E03');self.advance(4,3)
        # Compute from the values visible to a student (current rounded to 0.01 mA).
        shown=[float(f'{i:.2f}') for u,i in j]
        rs=[1000*u/i for (u,_),i in zip(j,shown)]
        for k,v in enumerate(rs+[sum(rs)/3],1):self.enter(4,k,f'{v:.10f}')
        self.snap('E04');self.advance(5,4)
        slope=1000*(j[2][0]-j[0][0])/(shown[2]-shown[0])
        self.enter(5,1,f'{slope:.10f}');self.snap('E05')
        self.click('OS_BACK','back');assert self.state['step']==4 and self.state['journal']==j,self.state
        # Correcting a completed answer invalidates that stage, but preserves readings.
        self.enter(4,4,f'{sum(rs)/3:.10f}'.replace('.',','));assert self.state['done_count']==3,self.state
        self.advance(5,4);assert math.isclose(float(flat(self.state['answers'])[0]),slope,rel_tol=1e-9)
        self.advance(6,5);self.enter(6,1,'3');self.enter(6,2,'1');self.advance(6,5)
        self.enter(6,1,'1');self.snap('E06');self.advance(6,6)
        self.click('B01','power');assert not self.state['power']
        self.advance(6,6) # real export button creates the report
        assert self.state['journal']==j and self.state['wire_count']==6,self.state
        self.snap('E06-export')
    def grade(self):
        sys.path.insert(0,str(ROOT/'core/tests'))
        from test_grading import run,fixture,write
        results,_=run(self.args.grader.resolve(),self.out/'reports',self.out/'graded')
        html=[r for r in results['results'] if r['file'].endswith('.html')]
        drafts=[r for r in results['results'] if r['file'].endswith('.sod')]
        assert len(html)==1 and drafts and len(html)+len(drafts)==len(results['results']),results
        r=html[0];assert r['status']=='graded' and (r['points'],r['max_points'])==(15,15),r
        assert r['rubric_version']=='LD3-1' and r['selected_for_summary'] and not r['practice_used'],r
        assert all(d['status']=='review' and not d['selected_for_summary'] for d in drafts),drafts
        # Separately verify all 64 synthetic analytical reports and bad units.
        f=self.out/'synthetic';f.mkdir();want={}
        for n in range(1,65):
            report=fixture('LD3',n,f'analytic-{n}');p=report['parameters'];us=[p['U1'],p['U2'],p['U3']]
            ii=[float(f'{1000*u/p["R"]:.2f}') for u in us];rr=[1000*u/i for u,i in zip(us,ii)]
            vals=dict(zip(['s4.q1','s4.q2','s4.q3'],rr));vals['s4.q4']=sum(rr)/3;vals['s5.q1']=1000*(us[-1]-us[0])/(ii[-1]-ii[0])
            for a in report['answers']:
                if a['id'] in vals:a['raw']=format(vals[a['id']],'.12g')
            report['note']='Synthetic analytical fixture, not a native GUI or physical measurement.'
            name=f'v{n:02d}.html';write(f/name,report);want[name]=15
        wrong=fixture('LD3',17,'unit-mistake');next(a for a in wrong['answers'] if a['id']=='s4.q1')['raw']='0.056'
        write(f/'wrong-unit.html',wrong);want['wrong-unit.html']=14
        synthetic,_=run(self.args.grader.resolve(),f,self.out/'synthetic-grades')
        assert len(synthetic['results'])==65,synthetic
        for item in synthetic['results']:
            assert item['status']=='graded' and item['max_points']==15 and item['points']==want[item['file']],item
        layout=subprocess.run([str(self.args.checker.resolve()),str(self.out/'geometry_all.tsv')],capture_output=True,text=True)
        (self.out/'geometry.log').write_text(layout.stdout+layout.stderr,encoding='utf-8')
        assert layout.returncode==0 and 'scenarios=7' in layout.stdout and 'errors=0' in layout.stdout,layout.stdout+layout.stderr
        result=dict(status='PASS',lab='LD3',variant=17,stages=6,native_os=os.name,
            mouse_clicks=sum(e['kind']=='mouse' for e in self.events),keyboard_entries=sum(e['kind']=='keyboard' for e in self.events),
            manual_wires=6,measured_points=3,geometry_scenarios=7,graded_html='15/15',rubric='LD3-1',
            synthetic_cases=65,screenshots=self.shots,registration='fixed test identity, not OS-typed',
            exclusions=['physical electrical instruments','all variants via native input','native menu-based draft restoration'])
        (self.out/'acceptance.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
        print('LD3_NATIVE_PASS: '+json.dumps(result,ensure_ascii=False),flush=True)
    def close(self):
        if self.proc and self.proc.poll() is None:
            try:self.proc.stdin.write(b'exit(0)\n');self.proc.stdin.flush();self.proc.wait(timeout=4)
            except (OSError,subprocess.TimeoutExpired):pass
            if self.proc.poll() is None:
                self.proc.terminate()
                try:self.proc.wait(timeout=10)
                except subprocess.TimeoutExpired:self.proc.kill();self.proc.wait(timeout=5)
        if hasattr(self,'log'):self.log.close()

def main():
    p=argparse.ArgumentParser()
    for key in ['scilab','core','grader','checker','output']:p.add_argument('--'+key,required=True,type=Path)
    t=NativeLD3(p.parse_args())
    try:t.start();t.work();t.grade()
    except Exception as exc:
        (t.out/'failure.txt').write_text(type(exc).__name__+': '+str(exc),encoding='utf-8')
        try:t.snap('failure')
        except Exception:pass
        raise
    finally:t.close()
if __name__=='__main__':main()
