#!/usr/bin/env python3
"""Real Windows/Linux OS mouse-and-keyboard acceptance for LD4 and LD5.

Student actions are native user32 / X11/XTest events delivered to genuine
Scilab controls. Test-only Scilab witnesses observe callbacks AFTER they fire.
No Python code invokes a Scilab callback or rewrites a laboratory's state.
Synthetic variant fixtures and fixed registration remain distinct from GUI proof.
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

REPO=Path(__file__).resolve().parents[1]
SCE=REPO/"tools"/"test_ld45_native.sce"
CANON4_R1=(("T01","T03"),("T04","T05"),("T06","T07"),
           ("T08","T02"),("T11","T07"),("T12","T08"))
CANON4_R2=(("T01","T03"),("T04","T05"),("T06","T09"),
           ("T10","T02"),("T11","T09"),("T12","T10"))
CANON4_SERIES=(("T01","T03"),("T04","T05"),("T06","T07"),
               ("T08","T09"),("T10","T02"),("T11","T07"),("T12","T10"))
CANON5=(("T01","T03"),("T04","T05"),("T06","T07"),
        ("T08","T09"),("T10","T02"),("T11","T09"),("T12","T10"))
assert len(CANON4_R1)==len(CANON4_R2)==6 and len(CANON4_SERIES)==len(CANON5)==7


def flatten(x):
    return sum((flatten(t) for t in x),[]) if isinstance(x,list) else [x]


def number(s):
    v=float(str(s).replace(",","."))
    if not math.isfinite(v):
        raise AssertionError("nonfinite number "+repr(s))
    return v


class Lab45:
    def __init__(self,args):
        self.args=args
        self.lab=args.lab
        self.path=args.output.resolve()/args.lab
        self.path.mkdir(parents=True,exist_ok=True)
        (self.path/"scihome").mkdir(exist_ok=True)
        self.desktop=Desktop(args.lab,self.path)
        self.events=[]
        self.screen_files=[]
        self.seq=-1
        self.proc=None
        self.env=dict(os.environ,
                      OS45_ROOT=REPO.as_posix(),
                      OS45_LAB=args.lab,
                      OS45_OUT=self.path.as_posix(),
                      LD_CORE_LIBRARY=str(args.core.resolve()),
                      LD_DATA_DIR=(self.path/"Ataskaitos").as_posix())
    def wait(self,previous,event,seconds=30):
        end=time.monotonic()+seconds;observed=None
        while time.monotonic()<end:
            if (self.path/"failure").exists():
                raise RuntimeError((self.path/"failure").read_text(encoding="utf-8"))
            if self.proc.poll() is not None:
                raise RuntimeError(f"{self.lab}: Scilab closed unexpectedly, code {self.proc.returncode}")
            try:
                raw=(self.path/"state.json").read_text(encoding="utf-8")
                raw=re.sub(r"\bnan\b","null",raw,flags=re.IGNORECASE)
                observed=json.loads(raw)
                if observed["seq"]>previous and observed["event"]==event:
                    self.state=observed
                    self.seq=int(observed["seq"])
                    return observed
            except (ValueError,OSError,KeyError,TypeError):pass
            time.sleep(.07)
        log=(self.path/"scilab.log").read_text(encoding="utf-8",errors="replace")
        raise TimeoutError(f"{self.lab}: expected {event} after {previous}; "
                           f"last state={str(observed)[:800]}, log={log[-6000:]}")
    def start(self):
        exe=self.args.scilab.resolve()
        if os.name=="nt":exe=exe.parent/"WScilex.exe"
        command=[str(exe),*([] if os.name=="nt" else ["-nw"]),"-nb",
                 "-scihome",str(self.path/"scihome"),"-f",str(SCE)]
        self.log=(self.path/"scilab.log").open("wb")
        self.proc=subprocess.Popen(command,stdin=subprocess.PIPE,stdout=self.log,
                                   stderr=subprocess.STDOUT,env=self.env,
                                   start_new_session=os.name!="nt")
        s=self.wait(-1,"ready",100)
        self.cfg=json.loads((self.path/"config.json").read_text(encoding="utf-8"))
        self.wires={}
        for row in (self.path/"wires.tsv").read_text(encoding="utf-8").splitlines():
            mode,a,b=row.split("\t")
            self.wires.setdefault(int(mode),[]).append((a,b))
        expected={
            "LD4":{1:CANON4_R1,2:CANON4_R2,3:CANON4_SERIES},
            "LD5":{1:CANON5}
        }[self.lab]
        for mode,pairs in expected.items():
            actual={frozenset(p) for p in self.wires[mode]}
            wanted={frozenset(p) for p in pairs}
            assert actual==wanted,(self.lab,mode,actual,wanted)
        assert s["step"]==1 and s["wire_count"]==0 and s["done_count"]==0,s
        assert s["assessment"] and not s["practice"],s
        deadline=time.monotonic()+25
        while True:
            try:self.desktop.locate();break
            except RuntimeError:
                if self.proc.poll() is not None or time.monotonic()>deadline:
                    raise
                time.sleep(.25)
        self.record("native_GUI_started",window=self.desktop.client_size)
    def record(self,kind,**info):
        self.events.append(dict(kind=kind,**info))
        (self.path/"actions.json").write_text(json.dumps(self.events,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    def point(self,tag,style):
        rows=[r.split("\t") for r in (self.path/"geometry.tsv").read_text(encoding="utf-8").splitlines()]
        rows=[r for r in rows if len(r)==13 and r[3]==tag and r[2]==style]
        assert len(rows)==1,(self.lab,self.state["step"],tag,rows)
        x,y,w,h=[float(v) for v in rows[0][4:8]]
        self.desktop.update_origin()
        ox,oy=self.desktop.client_origin; cw,ch=self.desktop.client_size
        pt=(round(ox+x+w/2),round(oy+ch-y-h/2))
        assert ox<=pt[0]<ox+cw and oy<=pt[1]<oy+ch,(tag,pt,(cw,ch))
        return pt
    def click(self,tag,event):
        prev=self.seq;pt=self.point(tag,"pushbutton")
        self.desktop.click_xy(*pt)
        st=self.wait(prev,event)
        self.record("real_OS_mouse",control=tag,x=pt[0],y=pt[1],step=st["step"])
        return st
    def enter(self,step,k,value):
        raw=str(value) if isinstance(value,str) else format(float(value),".11g")
        tag=f"A{step:02d}.{k:02d}"
        pt=self.point(tag,"edit");before=self.seq
        self.desktop.click_xy(*pt)
        self.desktop.key("ctrl+a")
        if os.name=="nt":self.desktop.type_text(raw)
        else:
            subprocess.run(["xdotool","type","--clearmodifiers","--delay","8","--",raw],
                           check=True,capture_output=True,text=True)
        self.desktop.key("Tab")
        st=self.wait(before,"answer")
        strings=[str(q) for q in flatten(st["answers"])]
        assert len(strings)>=k and strings[k-1]==raw,(tag,raw,strings)
        self.record("real_OS_keyboard",answer_tag=tag,typed=raw)
    def connect(self,pairs,expect):
        count=int(self.state["wire_count"])
        for x,y in pairs:
            st=self.click(x,"terminal")
            assert st["pending"]!="",(x,st)
            st=self.click(y,"terminal")
            count+=1
            assert st["pending"]=="" and st["wire_count"]==count,(x,y,st)
        assert count==expect,self.state
    def remove(self,x,y,expect):
        self.click(x,"terminal")
        s=self.click(y,"terminal")
        assert s["wire_count"]==expect and s["pending"]=="",s
    def press(self,step,count):
        st=self.click("OS_PRIMARY","primary")
        assert st["step"]==step and st["done_count"]==count,(step,count,st)
        return st
    def measure(self,expected_count):
        st=self.click("B03","measure")
        assert st["journal_count"]==expected_count,(expected_count,st)
        return st
    def input_values(self,step,values):
        for k,v in enumerate(values,1):self.enter(step,k,v)
    def snapshot(self,label):
        st=self.state
        lines=(self.path/"geometry.tsv").read_text(encoding="utf-8").splitlines()
        with (self.path/"geometry_all.tsv").open("a",encoding="utf-8") as dst:
            for row in lines:
                cols=row.split("\t");assert len(cols)==13,(label,row)
                cols[0]=f"{self.lab}-{label}"
                dst.write("\t".join(cols)+"\n")
        self.desktop.update_origin()
        x,y=self.desktop.client_origin;w,h=self.desktop.client_size
        target=self.path/(label+".png")
        if os.name=="nt":
            from PIL import ImageGrab
            ImageGrab.grab(bbox=(x,y,x+w,y+h)).save(target)
        else:
            code=("import gi,sys;gi.require_version('Gdk','3.0');"
                  "from gi.repository import Gdk;w=Gdk.get_default_root_window();"
                  "p=Gdk.pixbuf_get_from_window(w,*map(int,sys.argv[2:]));"
                  "assert p is not None;p.savev(sys.argv[1],'png',[],[])")
            subprocess.run(["/usr/bin/python3","-c",code,str(target),
                            str(x),str(y),str(w),str(h)],
                           check=True,env=self.env,timeout=20)
        self.screen_files.append(target.name)
        self.record("screen_capture",file=target.name,step=st["step"],done=st["done_count"])
    def physical_journal(self,expected):
        rows=self.state["journal"]
        assert len(rows)==expected,(self.lab,expected,rows)
        for row in rows:
            assert len(row)==3 and all(math.isfinite(number(v)) for v in row),row
        return rows
    def work_ld4(self):
        c=self.cfg
        self.snapshot("E01")
        self.press(1,0) # missing connections must not complete
        self.connect(self.wires[1],6)
        # Removing a genuine cable and reconnecting it must not yield credit
        self.remove("T11","T07",5)
        self.press(1,0)
        self.connect((("T07","T11"),),6)
        self.press(2,1)
        self.snapshot("E02")
        self.click("B03","measure");assert self.state["journal_count"]==0
        self.enter(2,1,"1+2");self.press(2,1)
        assert "skai" in self.state["status"].lower(),self.state
        self.enter(2,1,c["U1"]/c["R1nom"]*1000)
        self.click("B01","power")
        self.click("B02","switch")
        # intentionally measure out of the nominal order, as a student may do
        for idx,tag in enumerate(("B12","B11","B10"),1):
            self.click(tag,"voltage")
            self.measure(idx)
        rows=self.physical_journal(3)
        assert {int(row[0]) for row in rows}=={int(c["U1"]),int(c["U2"]),int(c["U3"])}
        # A wrong but well-formatted answer is stored and judged later.
        self.enter(2,1,"999");self.press(3,2)
        assert self.state["done_count"]==2
        self.click("OS_BACK","back")
        assert self.state["step"]==2
        assert str(flatten(self.state["answers"])[0])=="999",self.state
        self.enter(2,1,c["U1"]/c["R1nom"]*1000)
        self.press(3,2)
        self.snapshot("E03")
        assert not self.state["power"] and not self.state["switch"],self.state
        st=self.click("B13","resistor")
        assert st["mode"]==2 and st["wire_count"]==6 and not st["power"],st
        self.click("B01","power");self.click("B02","switch")
        for idx,tag in enumerate(("B10","B11","B12"),4):
            self.click(tag,"voltage");self.measure(idx)
        self.physical_journal(6)
        self.press(4,3)
        self.snapshot("E04")
        rows=self.state["journal"]
        r1_rows=[x for x in rows if x[2]==1]
        r2_rows=[x for x in rows if x[2]==2]
        assert len(r1_rows)==len(r2_rows)==3,rows
        def avg_r(rr):
            return sum(1000*number(row[0])/number(row[1]) for row in rr)/len(rr)
        r1m,r2m=avg_r(r1_rows),avg_r(r2_rows)
        self.input_values(4,[r1m,r2m,(r1m/c["R1nom"]-1)*100,(r2m/c["R2nom"]-1)*100])
        self.press(5,4)
        self.snapshot("E05")
        r1_rows.sort(key=lambda row:row[0])
        r2_rows.sort(key=lambda row:row[0])
        def slope(r):
            return 1000*(number(r[-1][0])-number(r[0][0]))/(number(r[-1][1])-number(r[0][1]))
        r1s,r2s=slope(r1_rows),slope(r2_rows)
        self.input_values(5,[r1s,r2s,1000/r2s])
        self.press(6,5)
        self.snapshot("E06")
        assert not self.state["power"] and not self.state["switch"],self.state
        # Check the interlock before rewiring. Electrical energy must be off.
        st=self.click("B01","power")
        assert st["power"],st
        st=self.click("T06","terminal")
        assert st["wire_count"]==6 and st["pending"]=="",st
        st=self.click("B01","power")
        assert not st["power"],st
        # Native terminal events: remove old R2 feed/probe, connect R1+R2.
        self.remove("T06","T09",5)
        self.remove("T11","T09",4)
        self.connect((("T06","T07"),("T08","T09"),("T11","T07")),7)
        self.click("B01","power");self.click("B02","switch")
        self.click("B12","voltage")
        self.measure(7)
        rows=self.physical_journal(7)
        series=next(x for x in rows if x[2]==3)
        self.enter(6,1,1000*number(series[0])/number(series[1]))
        self.press(7,6)
        self.snapshot("E07")
        self.input_values(7,["1","1"])
        self.press(7,7)
        self.snapshot("E07-validated")
        self.click("B01","power")
        assert not self.state["power"],self.state
        self.click("OS_PRIMARY","primary")
    def work_ld5(self):
        c=self.cfg
        self.snapshot("E01")
        self.press(1,0)
        self.connect(self.wires[1],7)
        self.remove("T11","T09",6)
        self.press(1,0)
        self.connect((("T09","T11"),),7)
        # A live source must never permit editing a terminal connection.
        st=self.click("B01","power")
        assert st["power"],st
        st=self.click("T11","terminal")
        assert st["wire_count"]==7 and st["pending"]=="",st
        st=self.click("B01","power")
        assert not st["power"],st
        self.press(2,1)
        self.snapshot("E02")
        active2=c["RV"]*c["P2"]/100
        u2=c["E"]*active2/(c["R1"]+active2)
        self.enter(2,1,"1+2")
        self.press(2,1)
        assert "skai" in self.state["status"].lower(),self.state
        self.enter(2,1,u2)
        self.measure(0)
        self.click("B01","power");self.click("B02","switch")
        self.click("B11","position")
        self.measure(1)
        self.measure(1) # duplicate not inserted
        self.press(3,2)
        self.snapshot("E03")
        self.click("B10","position");self.measure(2)
        self.click("B12","position");self.measure(3)
        self.press(4,3)
        self.snapshot("E04")
        rows=self.physical_journal(3)
        assert {x[2] for x in rows}=={1,2,3}
        def voltage(p):
            rv=c["RV"]*c[f"P{p}"]/100
            return c["E"]*rv/(c["R1"]+rv)
        u1,u3=voltage(1),voltage(3)
        self.input_values(4,[u1,u3,u3-u1,(u3-u1)/c["E"]*100])
        self.press(5,4)
        self.snapshot("E05")
        self.input_values(5,[c["E"]/(c["R1"]+active2)*1000,active2/(c["R1"]+active2)*100])
        self.press(6,5)
        self.snapshot("E06")
        self.input_values(6,["1","1"])
        self.press(6,6)
        self.snapshot("E06-validated")
        self.click("B01","power")
        assert not self.state["power"],self.state
        self.click("OS_PRIMARY","primary")
    def verify(self):
        expected=7 if self.lab=="LD4" else 6
        assert self.state["step"]==expected and self.state["done_count"]==expected,self.state
        assert self.state["assessment"] and not self.state["practice"],self.state
        assert self.state["wire_count"]==7,self.state
        want=7 if self.lab=="LD4" else 3
        self.physical_journal(want)
        reportroot=self.path/"Ataskaitos"
        end=time.monotonic()+25
        while time.monotonic()<end:
            reports=list(reportroot.rglob("*.html")) if reportroot.exists() else []
            if len(reports)==1:
                break
            time.sleep(.15)
        else:raise AssertionError("No HTML report exported by native primary button")
        self.report=reports[0]
        sys.path.insert(0,str(REPO/"core"/"tests"))
        from test_grading import run
        result,_=run(self.args.grader.resolve(),reportroot,self.path/"graded")
        graded=[x for x in result["results"] if x["file"].lower().endswith(".html")]
        assert len(graded)==1,graded
        item=graded[0];maximum={"LD4":27,"LD5":16}[self.lab]
        assert item["status"]=="graded" and (item["points"],item["max_points"])==(maximum,maximum),item
        assert item["mode"]=="assessment" and not item["practice_used"] and item["selected_for_summary"],item
        drafts=[x for x in result["results"] if x["file"].lower().endswith(".sod")]
        for d in drafts:
            assert d["status"]=="review" and not d["selected_for_summary"],d
        checker=subprocess.run([str(self.args.checker.resolve()),str(self.path/"geometry_all.tsv")],
                               capture_output=True,text=True)
        (self.path/"geometry.log").write_text(checker.stdout+checker.stderr,encoding="utf-8")
        scenario_count=len(self.screen_files)
        assert checker.returncode==0,checker.stdout+checker.stderr
        assert f"scenarios={scenario_count}" in checker.stdout and "errors=0" in checker.stdout,checker.stdout
        self.outcome=dict(status="PASS",lab=self.lab,os=os.name,variant=17,
            total_stages=expected,mouse_clicks=sum(x["kind"]=="real_OS_mouse" for x in self.events),
            keyboard_entries=sum(x["kind"]=="real_OS_keyboard" for x in self.events),
            main_circuit_cable_pairs={"LD4":7,"LD5":7}[self.lab],
            actual_measurements=want,geometry_scenarios=scenario_count,screen_files=self.screen_files,
            report=reports[0].name,score=maximum,rubric=item["rubric_version"],
            autostored_drafts=len(drafts),
            registration="fixed test identity, not manually typed",
            limitations="Native OS events in a real Scilab GUI, not physical handheld mouse or electrical equipment")
        (self.path/"acceptance.json").write_text(json.dumps(self.outcome,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
        print("LD45_NATIVE_PASS: "+json.dumps(self.outcome,ensure_ascii=False),flush=True)
    def run(self):
        self.start()
        if self.lab=="LD4":self.work_ld4()
        else:self.work_ld5()
        self.verify()
    def close(self):
        if self.proc is not None and self.proc.poll() is None:
            try:
                if self.proc.stdin:
                    self.proc.stdin.write(b"exit(0)\n");self.proc.stdin.flush()
                    self.proc.wait(timeout=4)
            except (OSError,subprocess.TimeoutExpired):pass
            if self.proc.poll() is None:
                self.proc.terminate()
                try:self.proc.wait(timeout=12)
                except subprocess.TimeoutExpired:self.proc.kill();self.proc.wait(timeout=5)
        if hasattr(self,"log"):self.log.close()


def main():
    a=argparse.ArgumentParser()
    for name in ("scilab","core","grader","checker","output"):
        a.add_argument("--"+name,required=True,type=Path)
    a.add_argument("--labs",choices=("LD4","LD5"),nargs="+",default=("LD4","LD5"))
    args=a.parse_args()
    for lab in args.labs:
        from argparse import Namespace
        t=Lab45(Namespace(**vars(args),lab=lab))
        try:
            t.run()
        except Exception as e:
            (t.path/"failure.txt").write_text(type(e).__name__+": "+str(e)+"\n",encoding="utf-8")
            log=t.path/"scilab.log"
            if log.exists():print(log.read_text(encoding="utf-8",errors="replace")[-7000:],file=sys.stderr)
            raise
        finally:t.close()


if __name__=="__main__":
    main()
