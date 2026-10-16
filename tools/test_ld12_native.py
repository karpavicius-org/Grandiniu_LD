#!/usr/bin/env python3
"""LD12 acceptance through real Windows/Linux mouse and keyboard events.

The fixed registration is a fixture. All laboratory actions use the OS, and
test-only Scilab witnesses observe the real callbacks after they have run.
Physics expectations use independent three-phase vectors and public journal readings.
"""
import argparse
import json
import cmath
import math
import os
from pathlib import Path
import subprocess
import sys
import time

from test_ld45_native import Lab45, flatten, number

REPO = Path(__file__).resolve().parents[1]
SCE = REPO / "tools/test_ld12_native.sce"
STAR=(("T01","T05"),("T02","T07"),("T03","T09"),("T06","T08"),("T08","T10"),("T10","T04"))
DELTA=(("T01","T05"),("T06","T02"),("T02","T07"),("T08","T03"),("T03","T09"),("T10","T01"))


class Lab12(Lab45):
    def start(self):
        self.env.update(OS12_ROOT=REPO.as_posix(), OS12_OUT=self.path.as_posix())
        exe = self.args.scilab.resolve()
        if os.name == "nt":
            exe = exe.parent / "WScilex.exe"
        command = [str(exe), *([] if os.name == "nt" else ["-nw"]), "-nb",
                   "-scihome", str(self.path / "scihome"), "-f", str(SCE)]
        self.log = (self.path / "scilab.log").open("wb")
        self.proc = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=self.log,
                                     stderr=subprocess.STDOUT, env=self.env,
                                     start_new_session=os.name != "nt")
        st = self.wait(-1, "ready", 100)
        self.cfg = json.loads((self.path / "config.json").read_text(encoding="utf-8"))
        assert (st["step"], st["done_count"], st["wire_count"]) == (1, 0, 0), st
        assert st["assessment"] and not st["practice"], st
        deadline = time.monotonic() + 25
        while True:
            try:
                self.desktop.locate()
                break
            except RuntimeError:
                if time.monotonic() > deadline or self.proc.poll() is not None:
                    raise
                time.sleep(.25)
        self.record("native_GUI_started", window=self.desktop.client_size)

    def choose(self, slot, choice):
        tag = f"A06.{slot:02d}"
        prev = self.seq
        pt = self.point(tag, "popupmenu")
        self.desktop.click_xy(*pt)
        self.desktop.key("Home")
        for _ in range(choice):
            self.desktop.key("Down")
        self.desktop.key("Return")
        self.desktop.key("Tab")
        st = self.wait(prev, "answer")
        assert str(flatten(st["answers"])[slot - 1]) == str(choice), st
        self.record("real_OS_keyboard", answer_tag=tag, selected=choice)

    def phasors(self):
        c=self.cfg
        source=[c['Ul']/math.sqrt(3)*cmath.exp(1j*a) for a in (0,-2*math.pi/3,2*math.pi/3)]
        star=[v/c['R'] for v in source]
        delta=[(source[k]-source[(k+1)%3])/c['R'] for k in range(3)]
        line=[delta[k]-delta[(k-1)%3] for k in range(3)]
        assert abs(sum(line))<1e-12
        py=sum((v*i.conjugate()).real for v,i in zip(source,star))
        pd=sum(((source[k]-source[(k+1)%3])*delta[k].conjugate()).real for k in range(3))
        assert math.isclose(pd,3*py,rel_tol=1e-12)
        return source,star,delta,line,py,pd

    def point_readings(self,mode,recorded_branch,selected_branch):
        import re
        rows=self.state['journal']
        if rows and not isinstance(rows[0],list):rows=[rows]
        row=next(row for row in rows if int(row[2])==mode)
        assert int(row[3])==recorded_branch,row
        source,star,delta,line,py,pd=self.phasors()
        k=selected_branch-1
        u=abs(source[k]) if mode==1 else abs(source[k]-source[(k+1)%3])
        i=abs((star if mode==1 else delta)[k])*1000
        assert math.isclose(number(row[0]),u,rel_tol=1e-10),(row,u)
        assert math.isclose(number(row[1]),i,rel_tol=1e-10),(row,i)
        assert self.state['voltage']==f"{u:.4f} V",self.state
        assert self.state['main_current']==f"{i:.3f} mA",self.state
        ends=('L1–N','L2–N','L3–N') if mode==1 else ('L1–L2','L2–L3','L3–L1')
        assert self.state['branch']==f"R{selected_branch} · {ends[k]}",self.state
        lines=flatten(self.state['journal_display'])
        name=('ŽVAIGŽDĖ','TRIKAMPIS')[mode-1]
        text=next(line for line in lines if line.startswith(name))
        assert f'R{recorded_branch}' in text,text
        values=re.search(r'Uf=([0-9.]+) V \| If=([0-9.]+) mA',text).groups()
        return tuple(map(number,values))

    def work(self):
        c=self.cfg
        self.snapshot('E01');self.press(1,0)
        self.connect(STAR,6)
        self.remove('T10','T04',5)
        self.enter(1,1,c['Ul']/math.sqrt(3));self.press(1,0)
        self.connect((('T04','T10'),),6)
        self.click('B01','power')
        st=self.click('T01','terminal');assert st['wire_count']==6 and not st['pending'],st
        self.click('B01','power')
        self.enter(1,1,'1+2');self.press(1,0)
        assert 'skai' in self.state['status'].lower(),self.state
        self.enter(1,1,'999');self.press(2,1)
        self.click('OS_BACK','back');assert str(flatten(self.state['answers'])[0])=='999',self.state
        self.enter(1,1,c['Ul']/math.sqrt(3));self.press(2,1)
        self.snapshot('E02');self.measure(0)
        self.click('B01','power');self.measure(0)
        self.click('B02','switch');self.measure(0) # no measuring branch selected
        self.click('B13','phase');self.measure(1)
        self.click('B14','phase');self.measure(1) # symmetric branch, no duplicate row
        uy,iy=self.point_readings(1,2,3)
        self.enter(2,1,uy/c['R']*1000);self.press(3,2)
        assert self.state['wire_count']==0 and not self.state['power'],self.state
        self.snapshot('E03')
        self.click('B10','mode');assert self.state['wire_count']==6,self.state
        self.click('B11','mode');assert self.state['wire_count']==0,self.state
        self.connect(DELTA[:-1],5)
        self.enter(3,1,c['Ul']);self.press(3,2) # missing final cable
        self.connect(DELTA[-1:],6);self.press(4,3)
        self.snapshot('E04');self.measure(1)
        self.click('B01','power');self.measure(1)
        self.click('B02','switch');self.click('B12','phase');self.measure(2)
        self.click('B13','phase');self.measure(2)
        ud,idelta=self.point_readings(2,1,2)
        self.enter(4,1,ud/c['R']*1000);self.press(5,4)
        self.snapshot('E05')
        il=math.sqrt(3)*idelta
        pd=math.sqrt(3)*c['Ul']*il;py=3*uy*iy
        assert math.isclose(pd,3*ud*idelta,rel_tol=1e-12)
        assert math.isclose(pd,3*py,rel_tol=1e-5)
        assert math.isclose(il,abs(self.phasors()[3][0])*1000,rel_tol=1e-5)
        answers=[il,pd,py];self.input_values(5,answers)
        self.enter(5,2,'1+2');self.press(5,4)
        self.enter(5,2,'999');self.press(6,5)
        self.click('OS_BACK','back');assert str(flatten(self.state['answers'])[1])=='999',self.state
        self.enter(5,2,pd);self.press(6,5)
        self.snapshot('E06');self.press(6,5)
        self.choose(1,2);self.choose(2,1);self.choose(3,1);self.press(6,6)
        assert str(flatten(self.state['answers'])[0])=='2',self.state
        self.choose(1,1);self.press(6,6);self.snapshot('E06-validated')
        self.click('B01','power');self.click('OS_PRIMARY','primary')

    def verify(self):
        assert self.state["done_count"] == 6 and self.state["journal_count"] == 2, self.state
        assert self.state["assessment"] and not self.state["practice"], self.state
        root = self.path / "Ataskaitos"
        reports = list(root.rglob("*.html"))
        assert len(reports) == 1, reports
        sys.path.insert(0, str(REPO / "core/tests"))
        from test_grading import run
        result, _ = run(self.args.grader.resolve(), root, self.path / "graded")
        graded = [r for r in result["results"] if r["file"].endswith(".html")]
        assert len(graded) == 1 and (graded[0]["points"], graded[0]["max_points"]) == (14, 14), graded
        assert graded[0]["selected_for_summary"] and graded[0]["rubric_version"] == "LD12-1", graded
        check = subprocess.run([str(self.args.checker.resolve()), str(self.path / "geometry_all.tsv")],
                               capture_output=True, text=True)
        (self.path / "geometry.log").write_text(check.stdout + check.stderr, encoding="utf-8")
        assert check.returncode == 0, check.stdout + check.stderr
        result = dict(status="PASS", lab="LD12", os=os.name, variant=17, stages=6,
                      circuit_wires=6, measurements=2, report_score="14/14",
                      geometry_scenarios=len(self.screen_files), screen_files=self.screen_files,
                      mouse_clicks=sum(x["kind"] == "real_OS_mouse" for x in self.events),
                      keyboard_entries=sum(x["kind"] == "real_OS_keyboard" for x in self.events),
                      independent_complex_phasors=True, manually_connected_wires=12,
                      limitations="Fixed registration; real OS events in CI, not physical electrical equipment")
        (self.path / "acceptance.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print("LD12_NATIVE_PASS: " + json.dumps(result, ensure_ascii=False), flush=True)


def main():
    parser = argparse.ArgumentParser()
    for name in ("scilab", "core", "grader", "checker", "output"):
        parser.add_argument("--" + name, required=True, type=Path)
    args = parser.parse_args()
    lab = Lab12(argparse.Namespace(**vars(args), lab="LD12"))
    try:
        lab.start()
        lab.work()
        lab.verify()
    except Exception as e:
        (lab.path / "failure.txt").write_text(type(e).__name__ + ": " + str(e), encoding="utf-8")
        raise
    finally:
        lab.close()


if __name__ == "__main__":
    main()
