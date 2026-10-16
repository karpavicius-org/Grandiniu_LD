#!/usr/bin/env python3
"""LD11 acceptance through real Windows/Linux mouse and keyboard events.

The fixed registration is a fixture. All laboratory actions use the OS, and
test-only Scilab witnesses observe the real callbacks after they have run.
Physics expectations use independent complex admittance and recorded readings.
"""
import argparse
import json
import math
import os
from pathlib import Path
import subprocess
import sys
import time

from test_ld45_native import Lab45, flatten, number

REPO = Path(__file__).resolve().parents[1]
SCE = REPO / "tools/test_ld11_native.sce"
WIRES = (("T01", "T03"), ("T04", "T05"), ("T06", "T07"), ("T08", "T02"))
CAPACITOR = (("T07", "T09"), ("T10", "T02"))


class Lab11(Lab45):
    def start(self):
        self.env.update(OS11_ROOT=REPO.as_posix(), OS11_OUT=self.path.as_posix())
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

    def point_readings(self, mode):
        import re
        rows = self.state['journal']
        if rows and not isinstance(rows[0], list):
            rows = [rows]
        row = next(row for row in rows if int(row[2]) == mode)
        c = self.cfg
        w = 2 * math.pi * 50
        y = 1 / complex(c['R'], w * c['L']) + complex(0, w*c['Ck'] if mode == 2 else 0)
        expected_i, expected_p = c['E']*abs(y)*1000, c['E']**2*y.real*1000
        assert math.isclose(number(row[1]), expected_i, rel_tol=1e-10), (row, expected_i)
        assert math.isclose(number(row[3]), expected_p, rel_tol=1e-10), (row, expected_p)
        assert self.state['main_current'] == f"{expected_i:.3f} mA", self.state
        assert self.state['active_power'] == f"{expected_p:.3f} mW", self.state
        # Use actual public journal strings to calculate the answers entered by OS keys.
        lines = flatten(self.state['journal_display'])
        name = ('BE Ck', 'SU Ck')[mode-1]
        index = next(i for i, line in enumerate(lines) if line.startswith(name))
        u = number(re.search(r'U=([0-9.]+) V', lines[index]).group(1))
        i, p = map(number, re.search(r'I=([0-9.]+) mA \| P=([0-9.]+) mW', lines[index+1]).groups())
        assert f"{expected_i:.6f}" in lines[index+1], lines
        return u, i, p

    def work(self):
        c = self.cfg
        w = 2*math.pi*50
        z = complex(c['R'], w*c['L'])
        self.snapshot('E01')
        self.press(1, 0)
        self.click('B11', 'mode')
        assert self.state['wire_count'] == 0, self.state
        self.click('B10', 'mode')
        self.connect(WIRES, 4)
        self.remove('T08', 'T02', 3)
        self.enter(1, 1, c['R']/abs(z))
        self.press(1, 0)
        self.connect((('T02', 'T08'),), 4)
        self.click('B01', 'power')
        st = self.click('T01', 'terminal')
        assert st['wire_count'] == 4 and not st['pending'], st
        self.click('B01', 'power')
        self.enter(1, 1, '1+2')
        self.press(1, 0)
        assert 'skai' in self.state['status'].lower(), self.state
        self.enter(1, 1, '999')
        self.press(2, 1)
        self.click('OS_BACK', 'back')
        assert str(flatten(self.state['answers'])[0]) == '999', self.state
        self.enter(1, 1, c['R']/abs(z))
        self.press(2, 1)
        self.snapshot('E02')
        self.measure(0)
        self.click('B01', 'power')
        self.measure(0)
        self.click('B02', 'switch')
        self.measure(1)
        self.measure(1)
        u1, i1, p1 = self.point_readings(1)
        s1 = u1*i1
        self.input_values(2, [s1, math.sqrt((s1-p1)*(s1+p1)), p1/s1])
        self.press(3, 2)
        self.snapshot('E03')
        self.press(3, 2)
        self.click('B11', 'mode')  # a preview still has no compensation wires
        assert self.state['wire_count'] == 0, self.state
        self.enter(3, 1, z.imag/(w*abs(z)**2)*1e6)
        self.press(4, 3)
        assert self.state['wire_count'] == 4 and not self.state['power'], self.state
        self.snapshot('E04')
        self.press(4, 3)
        self.connect(CAPACITOR, 6)
        self.click('B10', 'mode')
        assert self.state['wire_count'] == 4 and not self.state['power'], self.state
        # The actual UI disables Matuoti in the wrong mode; an OS click is inert.
        previous = self.seq
        self.desktop.click_xy(*self.point('B03', 'pushbutton'))
        time.sleep(.25)
        observed = json.loads((self.path / 'state.json').read_text(encoding='utf-8'))
        assert observed['seq'] == previous and observed['journal_count'] == 1, observed
        self.record('real_OS_mouse', control='B03', disabled=True, step=4)
        self.click('B11', 'mode')
        assert self.state['wire_count'] == 6, self.state
        self.click('B01', 'power')
        self.click('B02', 'switch')
        self.measure(2)
        self.measure(2)
        u2, i2, p2 = self.point_readings(2)
        assert i2 < i1 and math.isclose(p1, p2, abs_tol=1e-6), (i1, i2, p1, p2)
        self.press(5, 4)
        self.snapshot('E05')
        s2 = u2*i2
        # The displayed component values are exact bank parameters, with Ck in microfarads.
        displayed_ck = number(self.state['capacitor'].split()[0])/1e6
        y2 = 1/z + complex(0, w*displayed_ck)
        q2 = abs(y2.imag)*u2*u2*1000
        assert math.isclose(q2, abs((1/z).imag+w*c['Ck'])*u2*u2*1000, rel_tol=1e-9)
        answers = [s2, q2, p2/s2, s1-s2]
        self.input_values(5, answers)
        self.enter(5, 2, '1+2')
        self.press(5, 4)
        self.enter(5, 2, '999')
        self.press(6, 5)
        self.click('OS_BACK', 'back')
        assert str(flatten(self.state['answers'])[1]) == '999', self.state
        self.enter(5, 2, answers[1])
        self.press(6, 5)
        self.snapshot('E06')
        self.press(6, 5)
        self.choose(1, 2)
        self.choose(2, 1)
        self.choose(3, 1)
        self.press(6, 6)
        assert str(flatten(self.state['answers'])[0]) == '2', self.state
        self.choose(1, 1)
        self.press(6, 6)
        self.snapshot('E06-validated')
        self.click('B01', 'power')
        self.click('OS_PRIMARY', 'primary')

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
        assert len(graded) == 1 and (graded[0]["points"], graded[0]["max_points"]) == (20, 20), graded
        assert graded[0]["selected_for_summary"] and graded[0]["rubric_version"] == "LD11-1", graded
        check = subprocess.run([str(self.args.checker.resolve()), str(self.path / "geometry_all.tsv")],
                               capture_output=True, text=True)
        (self.path / "geometry.log").write_text(check.stdout + check.stderr, encoding="utf-8")
        assert check.returncode == 0, check.stdout + check.stderr
        result = dict(status="PASS", lab="LD11", os=os.name, variant=17, stages=6,
                      circuit_wires=6, measurements=2, report_score="20/20",
                      geometry_scenarios=len(self.screen_files), screen_files=self.screen_files,
                      mouse_clicks=sum(x["kind"] == "real_OS_mouse" for x in self.events),
                      keyboard_entries=sum(x["kind"] == "real_OS_keyboard" for x in self.events),
                      independent_complex_admittance=True,
                      limitations="Fixed registration; real OS events in CI, not physical electrical equipment")
        (self.path / "acceptance.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print("LD11_NATIVE_PASS: " + json.dumps(result, ensure_ascii=False), flush=True)


def main():
    parser = argparse.ArgumentParser()
    for name in ("scilab", "core", "grader", "checker", "output"):
        parser.add_argument("--" + name, required=True, type=Path)
    args = parser.parse_args()
    lab = Lab11(argparse.Namespace(**vars(args), lab="LD11"))
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
