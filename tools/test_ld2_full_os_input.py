#!/usr/bin/env python3
"""Full LD2 student acceptance using real OS mouse and keyboard input.

Every one of twelve student stages is performed through visible native Scilab
controls, not by directly invoking a callback, editing the student's program
state, or reconstructing virtual measurements. Input is injected by Windows
user32 or Linux X11/XTest. Reference values are read-only test fixtures, and
registration is fixed to variant 17. The production LD2 code is not changed.
"""
import argparse
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
SCENARIO=REPO/"tools"/"test_ld2_full_os_input.sce"


def finite(value):
    if not math.isfinite(float(value)):
        raise AssertionError(f"Nonfinite measurement/answer: {value!r}")
    return float(value)


def flatten(x):
    if isinstance(x,list):
        out=[]
        for item in x:out+=flatten(item)
        return out
    return [x]


def as_float(x):
    return finite(x)


class LD2RealUser:
    def __init__(self,args):
        self.args=args
        self.root=args.output.resolve()
        self.root.mkdir(parents=True,exist_ok=True)
        (self.root/"scihome").mkdir(exist_ok=True)
        self.desktop=Desktop("LD2",self.root)
        self.proc=None
        self.log=None
        self.seq=-1
        self.events=[]
        self.shots=[]
        self.step_snapshots=[]
        self.state_file=self.root/"state.json"
        self.geom_file=self.root/"geometry.tsv"
        self.report_dir=self.root/"Studento ataskaitos"
        self.env=dict(os.environ,
                      LD2_NATIVE_OUT=self.root.as_posix(),
                      LD2_NATIVE_ROOT=REPO.as_posix(),
                      LD_CORE_LIBRARY=str(args.core.resolve()),
                      LD_DATA_DIR=self.report_dir.as_posix())

    def start(self):
        exe=self.args.scilab.resolve()
        if os.name=="nt":
            exe=exe.parent/"WScilex.exe"
        command=[str(exe)]
        if os.name!="nt":
            command+=["-nw"]
        command+=["-nb","-scihome",str(self.root/"scihome"),"-f",str(SCENARIO)]
        self.log=(self.root/"scilab.log").open("wb")
        self.proc=subprocess.Popen(command,env=self.env,
                                   stdin=subprocess.PIPE,
                                   stdout=self.log,stderr=subprocess.STDOUT,
                                   start_new_session=(os.name!="nt"))
        self.wait_file("ready",90)
        self.cfg=json.loads((self.root/"config.json").read_text(encoding="utf-8"))
        self.ref=json.loads((self.root/"references.json").read_text(encoding="utf-8"))
        self.wires={}
        for line in (self.root/"wiring.tsv").read_text(encoding="utf-8").splitlines():
            phase,a,b=line.split("\t")
            self.wires.setdefault(phase,[]).append((a,b))
        self.probes={}
        for line in (self.root/"probes.tsv").read_text(encoding="utf-8").splitlines():
            phase,target,a,b,c,d=line.split("\t")
            self.probes[(phase,target)]=((a,b),(c,d))
        assert [len(self.wires[x]) for x in ("RC","RL","RLC")]==[4,4,5],self.wires
        deadline=time.monotonic()+25
        while True:
            try:
                self.desktop.locate()
                break
            except RuntimeError:
                if self.proc.poll() is not None:
                    raise AssertionError(f"LD2 Scilab exited before native GUI appears ({self.proc.returncode})")
                if time.monotonic()>deadline:
                    raise
                time.sleep(.22)
        state=self.wait_event(-1,"ready",timeout=15)
        assert state["step"]==1 and state["completed_count"]==0,state
        assert state["assessment"] and not state["practice"],state
        self.events.append(dict(action="native_gui_open",client_size=self.desktop.client_size))

    def wait_file(self,filename,timeout=45):
        deadline=time.monotonic()+timeout
        while not (self.root/filename).exists():
            if (self.root/"failure").exists():
                raise RuntimeError((self.root/"failure").read_text(encoding="utf-8",errors="replace"))
            if self.proc.poll() is not None:
                raise RuntimeError(f"LD2 Scilab exited before {filename}: {self.proc.returncode}")
            if time.monotonic()>deadline:
                raise TimeoutError(f"LD2 {filename} never appeared; Scilab tail:\n"+
                                   (self.root/"scilab.log").read_text(encoding="utf-8",errors="replace")[-5000:])
            time.sleep(.1)

    def peek(self):
        try:
            content=self.state_file.read_text(encoding="utf-8")
            content=re.sub(r"(?<![a-zA-Z])(?:nan|NaN)(?![a-zA-Z])","null",content)
            return json.loads(content)
        except (OSError,ValueError,TypeError):
            return None

    def wait_event(self,after,event,timeout=30):
        deadline=time.monotonic()+timeout
        last=None
        while time.monotonic()<deadline:
            last=self.peek()
            if last and last["seq"]>after and last["event"]==event:
                self.state=last
                self.seq=int(last["seq"])
                return last
            if (self.root/"failure").exists():
                raise RuntimeError((self.root/"failure").read_text(encoding="utf-8",errors="replace"))
            if self.proc.poll() is not None:
                raise RuntimeError(f"LD2 Scilab exited while awaiting {event}: exit={self.proc.returncode}")
            time.sleep(.07)
        raise TimeoutError(f"Native LD2 callback {event!r} not observed after seq={after}, "
                           f"last={str(last)[:2000]}, log_tail="+
                           (self.root/"scilab.log").read_text(encoding="utf-8",errors="replace")[-4000:])

    def location(self,tag,style):
        # The native desktop driver owns pointer injection; the lab harness
        # resolves visible Scilab controls from the same geometry audit used
        # by the already passing LD1/LD6–LD8 real-mouse tests.
        rows=[line.split("\t") for line in self.geom_file.read_text(encoding="utf-8").splitlines()]
        matches=[r for r in rows if len(r)>=8 and r[3]==tag and r[2]==style]
        if len(matches)!=1:
            raise AssertionError(f"LD2 step {self.state['step']}: expected exactly one visible "
                                 f"{style} control {tag}, got {matches!r}")
        x,y,w,h=[float(z) for z in matches[0][4:8]]
        self.desktop.update_origin()
        ox,oy=self.desktop.client_origin
        cw,ch=self.desktop.client_size
        pos=(round(ox+x+w/2),round(oy+ch-y-h/2))
        assert ox<=pos[0]<ox+cw and oy<=pos[1]<oy+ch,(tag,pos,self.desktop.client_size)
        return pos

    def mouse(self,tag,event,expected_step=None):
        x,y=self.location(tag,"pushbutton")
        prev=self.seq
        self.desktop.click_xy(x,y)
        state=self.wait_event(prev,event)
        if expected_step is not None and state["step"]!=expected_step:
            raise AssertionError(f"{tag} should have reached step {expected_step}: {state}")
        self.events.append(dict(action="OS_left_click",tag=tag,event=event,point=[x,y],
                                step=state["step"],complete=state["completed_count"]))
        return state

    def wire_pair(self,first,second):
        before=int(self.state["connections"])
        st=self.mouse(first,"terminal")
        assert st["selected_terminal"]!="",("first terminal not selected",first,st)
        st=self.mouse(second,"terminal")
        assert st["selected_terminal"]=="",("terminal left pending",second,st)
        assert st["connections"]==before+1,("wire missing",first,second,st)
        return st

    def connect_main(self,phase):
        before=self.state["connections"]
        assert before==0,(phase,before,self.state["step"])
        for first,second in self.wires[phase]:
            self.wire_pair(first,second)
        st=self.state
        assert st["connections"]==len(self.wires[phase]),st
        self.events.append(dict(action="manually_connected_circuit",phase=phase,pairs=len(self.wires[phase])))

    def probe(self,phase,target):
        # The genuine "remove probes" button preserves the main wiring.
        before=self.state["connections"]
        st=self.mouse("B13","remove_probes")
        assert st["connections"] in (before,before-2),st
        for first,second in self.probes[(phase,target)]:
            self.wire_pair(first,second)
        assert self.state["connections"]==len(self.wires[phase])+2,self.state
        self.events.append(dict(action="changed_real_voltmeter_probes",phase=phase,target=target))

    def frequency(self,f):
        f=finite(f)
        assert 1<=f<=self.cfg["F_MAX"],f
        loc=self.location("F04","edit")
        prev=self.seq
        self.desktop.click_xy(*loc)
        self.desktop.key("ctrl+a")
        self.type_real_text(f"{f:.12g}")
        self.desktop.key("Tab")
        # The Scilab edit callback may apply on loss of focus. If it does not,
        # click the visible "Taikyti" button, never execute its callback directly.
        try:
            st=self.wait_event(prev,"frequency",timeout=1.8)
        except TimeoutError:
            st=self.mouse("B16","frequency")
        if not math.isclose(as_float(st["frequency"]),f,rel_tol=2e-10,abs_tol=1e-6):
            raise AssertionError(f"Frequency was not applied via actual keys: {f}, state={st}")
        self.events.append(dict(action="native_frequency_input",hz=f,step=st["step"]))

    def type_real_text(self,text):
        if os.name=="nt":
            self.desktop.type_text(str(text))
        else:
            # Negative phase angles must be passed as data, not flags to xdotool.
            subprocess.run(["xdotool","type","--clearmodifiers","--delay","8","--",str(text)],
                           check=True,capture_output=True,text=True)

    def type_answer(self,step,k,value):
        value=finite(value)
        tag=f"A{step:02d}.{k:02d}"
        prev=self.seq
        x,y=self.location(tag,"edit")
        self.desktop.click_xy(x,y)
        self.desktop.key("ctrl+a")
        entered=f"{value:.12g}"
        self.type_real_text(entered)
        self.desktop.key("Tab")
        try:
            st=self.wait_event(prev,"answer",timeout=3)
        except TimeoutError:
            # On some Scilab versions, an edit field's callback only runs on
            # Enter. Use the real keyboard, not an artificial function call.
            self.desktop.key("Return")
            st=self.wait_event(prev,"answer",timeout=12)
        entered_strings=[str(x) for x in flatten(st["answers"])]
        assert len(entered_strings)>=k,st
        stored=entered_strings[k-1]
        try:
            observed=finite(stored.replace(",","."))
        except (ValueError,TypeError) as e:
            raise AssertionError(f"LD2 did not store OS-typed answer {tag}: {stored!r}") from e
        assert math.isclose(observed,value,rel_tol=3e-11,abs_tol=1e-8),(tag,entered,stored)
        self.events.append(dict(action="native_keyboard_answer",field=tag,text=entered))

    def fill(self,step,values):
        for k,val in enumerate(values,1):
            self.type_answer(step,k,val)

    def primary(self,expected_step,expected_completed):
        st=self.mouse("B04","primary",expected_step=expected_step)
        assert st["completed_count"]==expected_completed,(expected_completed,st)
        self.events.append(dict(action="validated_stage",step=expected_step,
                                completed_count=expected_completed))
        return st

    def screenshot(self,step):
        target=self.root/f"E{step:02d}.png"
        self.desktop.update_origin()
        if os.name=="nt":
            import ctypes
            from ctypes import wintypes
            from PIL import ImageGrab
            rect=wintypes.RECT()
            assert self.desktop.user.GetWindowRect(self.desktop.window,ctypes.byref(rect))
            ImageGrab.grab(bbox=(rect.left,rect.top,rect.right,rect.bottom)).save(target)
        else:
            subprocess.run(["/usr/bin/python3",str(REPO/"studentui"/"capture_window.py"),
                            "LD2 · OS INPUT TEST",str(target)],
                           env=self.env,check=True,stdout=subprocess.DEVNULL,timeout=20)
        self.shots.append(target.name)
        self.step_snapshots.append(dict(step=step,completed=self.state["completed_count"],
                                        connections=self.state["connections"],power=self.state["power"]))

    def scope(self):
        self.screenshot(self.state["step"])

    def measure_rc_rl(self,phase,targets):
        assert self.state["phase"]==phase
        st=self.mouse("B09","power")
        assert st["power"],st
        st=self.mouse("B14","current")
        assert finite(st["amp"])>0,st
        for target in targets:
            self.probe(phase,target)
            st=self.mouse("B15","voltage")
            assert finite(st["voltage"])>0,st
            assert st["target"]==target,(target,st)

    def take_peak(self,f,kind,expected_count):
        self.frequency(f)
        st=self.mouse("B15","voltage")
        assert st["target"]==kind,(kind,st)
        st=self.mouse("B21" if self.state["step"]==9 else "B23",
                      "resonance_point" if self.state["step"]==9 else "peak_point")
        key="res_f" if st["step"]==9 else "peak_f"
        assert len(flatten(st[key]))==expected_count,(key,expected_count,st)
        return st

    def test(self):
        c=self.cfg
        ref=self.ref
        self.scope()
        self.primary(2,1)
        self.scope()
        # Two genuine erroneous user actions: incomplete circuit and invalid
        # wire do not bypass the student-facing interlock.
        st=self.mouse("B04","primary",expected_step=2)
        assert st["completed_count"]==1,st
        before=st["connections"]
        st=self.mouse(self.wires["RC"][0][0],"terminal")
        st=self.mouse(self.wires["RC"][-1][-1],"terminal")
        assert st["selected_terminal"]=="" and st["connections"]==before,st
        assert "nereikalinga" in st["status"].lower() or "jungtis" in st["status"].lower(),st
        self.connect_main("RC")
        self.primary(3,2)
        self.scope()
        self.fill(3,flatten(ref["rc"]))
        self.primary(4,3)
        self.scope()
        self.measure_rc_rl("RC",("UR","UC","UE"))
        self.fill(4,(c["E_RC"],flatten(ref["rc"])[2]))
        self.primary(5,4)
        self.scope()
        self.connect_main("RL")
        self.primary(6,5)
        self.scope()
        self.fill(6,flatten(ref["rl"]))
        self.primary(7,6)
        self.scope()
        self.measure_rc_rl("RL",("UR","UL","UE"))
        self.fill(7,(c["E_RL"],flatten(ref["rl"])[2]))
        self.primary(8,7)
        self.scope()
        self.connect_main("RLC")
        self.primary(9,8)
        self.scope()
        self.probe("RLC","UR")
        st=self.mouse("B09","power")
        assert st["power"],st
        f0,bw=ref["f0"],ref["bw"]
        for idx,f in enumerate((f0-bw/2,f0,f0+bw/2),1):
            st=self.take_peak(f,"UR",idx)
        self.fill(9,(f0,f0,1000/f0,c["E_RLC"]))
        self.primary(10,9)
        self.scope()
        for target,center in (("UL",ref["fl"]),("UC",ref["fc"]),("ULC",ref["f0"])):
            self.probe("RLC",target)
            for delta in (-bw/2,0,bw/2):
                st=self.take_peak(center+delta,target,
                                  len(flatten(self.state["peak_f"]))+1)
        triples=list(zip(flatten(self.state["peak_target"]),
                         flatten(self.state["peak_f"]),
                         flatten(self.state["peak_u"])))
        def extreme(kind,highest=True):
            matches=[(finite(fr),finite(u)) for tag,fr,u in triples if tag==kind]
            assert len(matches)==3,(kind,matches)
            return max(matches,key=lambda x:x[1]) if highest else min(matches,key=lambda x:x[1])
        fl,ul=extreme("UL")
        fc,uc=extreme("UC")
        fz,uz=extreme("ULC",highest=False)
        self.fill(10,(ul,uc,uz,fl,fc,fz))
        self.primary(11,10)
        self.scope()
        self.probe("RLC","UR")
        for frequency,tag,event in ((ref["f1"],"B24","f1"),(ref["f2"],"B25","f2")):
            self.frequency(frequency)
            self.mouse("B15","voltage")
            state=self.mouse(tag,event)
            assert math.isclose(finite(state[event]),frequency,rel_tol=1e-10),state
        threshold=c["E_RLC"]/math.sqrt(2)
        self.fill(11,(threshold,ref["f1"],ref["f2"],ref["bw"],ref["q"]))
        self.primary(12,11)
        self.scope()
        self.probe("RLC","UR")
        state=self.mouse("B26","sweep")
        sweep=[int(round(finite(x))) for x in flatten(state["sweep_f"])]
        assert sweep==list(range(0,int(c["F_MAX"])+1,1000)),sweep
        state=self.mouse("B04","primary",expected_step=12)
        assert state["completed_count"]==12,state
        assert state["assessment"] and not state["practice"],state
        self.screenshot(12)
        self.wait_report()
        assert len(self.shots)>=12,self.shots
        self.events.append(dict(action="all_twelve_stages_completed",events=len(self.events)))

    def wait_report(self):
        deadline=time.monotonic()+20
        while time.monotonic()<deadline:
            files=list(self.report_dir.glob("*.html")) if self.report_dir.exists() else []
            if len(files)==1:
                self.report=files[0]
                return
            time.sleep(.1)
        raise AssertionError(f"LD2 actual final button click did not create one HTML report: {self.report_dir}")

    def grade(self):
        sys.path.insert(0,str(REPO/"core"/"tests"))
        from test_grading import run
        parsed,_=run(self.args.grader.resolve(),self.report_dir,self.root/"graded")
        html=[x for x in parsed["results"] if str(x["file"]).lower().endswith(".html")]
        drafts=[x for x in parsed["results"] if str(x["file"]).lower().endswith(".sod")]
        assert len(html)==1 and len(html)+len(drafts)==len(parsed["results"]),parsed
        result=html[0]
        assert result["status"]=="graded" and result["points"]==result["max_points"],result
        assert result["rubric_version"]=="LD2-1" and result["selected_for_summary"],result
        assert result["mode"]=="assessment" and not result["practice_used"],result
        for draft in drafts:
            assert draft["status"]=="review" and not draft["selected_for_summary"],draft
        self.grade_result=result
        self.drafts=len(drafts)
        checker=subprocess.run([str(self.args.checker.resolve()),str(self.geom_file)],
                               capture_output=True,text=True)
        (self.root/"geometry.log").write_text(checker.stdout+checker.stderr,encoding="utf-8")
        assert checker.returncode==0,checker.stdout+checker.stderr

    def save(self):
        report=dict(status="PASS",lab="LD2",os=os.name,variant=17,stages=12,
                    genuine_os_mouse_clicks=sum(x["action"]=="OS_left_click" for x in self.events),
                    native_keyboard_values=sum(x["action"]=="native_keyboard_answer" for x in self.events),
                    frequency_settings=sum(x["action"]=="native_frequency_input" for x in self.events),
                    manual_main_wires=4+4+5,voltmeter_changes=sum(x["action"]=="changed_real_voltmeter_probes" for x in self.events),
                    recorded_resonance_points=3,recorded_extrema_points=9,
                    half_power_samples=2,measured_sweep_points=11,
                    screenshot_count=len(self.shots),screenshots=self.shots,
                    report=self.report.name,autosaved_drafts=self.drafts,
                    grading={"points":self.grade_result["points"],"maximum":self.grade_result["max_points"],
                             "rubric":self.grade_result["rubric_version"]},
                    student_identity="fixed test fixture; registration modal not driven by OS",
                    method="Native Windows user32 or Linux X11/XTest events in actual Scilab window",
                    limitations="Not a human-held mouse or external electrical instruments.")
        (self.root/"acceptance.json").write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
        (self.root/"actions.json").write_text(json.dumps(self.events,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
        print("LD2_NATIVE_FULL_PASS: "+json.dumps(report,ensure_ascii=False),flush=True)

    def shutdown(self):
        if self.proc is None:return
        try:
            if self.proc.poll() is None and self.proc.stdin:
                try:
                    self.proc.stdin.write(b"exit(0)\n")
                    self.proc.stdin.flush()
                    self.proc.wait(timeout=4)
                except (OSError,subprocess.TimeoutExpired):
                    pass
            if self.proc.poll() is None:
                self.proc.terminate()
                try:self.proc.wait(timeout=15)
                except subprocess.TimeoutExpired:self.proc.kill();self.proc.wait(timeout=5)
        finally:
            if self.log is not None:self.log.close()


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scilab",required=True,type=Path)
    parser.add_argument("--core",required=True,type=Path)
    parser.add_argument("--grader",required=True,type=Path)
    parser.add_argument("--checker",required=True,type=Path)
    parser.add_argument("--output",required=True,type=Path)
    args=parser.parse_args()
    user=LD2RealUser(args)
    try:
        user.start()
        user.test()
        user.grade()
        user.save()
    except Exception as exc:
        (user.root/"failure.txt").write_text(f"{type(exc).__name__}: {exc}\n",encoding="utf-8")
        try:
            if user.proc and user.proc.poll() is None:user.screenshot("failure")
        except Exception:
            pass
        log=(user.root/"scilab.log")
        if log.exists():
            print(log.read_text(encoding="utf-8",errors="replace")[-5000:],file=sys.stderr)
        raise
    finally:
        user.shutdown()


if __name__=="__main__":
    main()
