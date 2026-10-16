#!/usr/bin/env python3
"""LD10 acceptance through real Windows/Linux mouse and keyboard events.

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
SCE = REPO / "tools/test_ld10_native.sce"
WIRES = (("T01", "T03"), ("T04", "T05"), ("T06", "T07"),
         ("T07", "T09"), ("T09", "T11"), ("T08", "T02"),
         ("T08", "T10"), ("T10", "T12"))


class Lab10(Lab45):
    def start(self):
        self.env.update(OS10_ROOT=REPO.as_posix(), OS10_OUT=self.path.as_posix())
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

    def point_readings(self, tag):
        rows = [r for r in self.state["journal"] if int(r[2]) == tag]
        assert len(rows) == 4, rows
        measured = {int(r[4]): number(r[1]) for r in rows}
        u = number(rows[0][0])
        c = self.cfg
        f0 = 1 / (2 * math.pi * math.sqrt(c["L"] * c["C"]))
        w = 2 * math.pi * (.5, 1, 2)[tag - 1] * f0
        admittance = complex(1 / c["R"], w * c["C"] - 1 / (w * c["L"]))
        expected = {1: c["E"] / c["R"] * 1000,
                    2: c["E"] / (w * c["L"]) * 1000,
                    3: c["E"] * w * c["C"] * 1000,
                    4: c["E"] * abs(admittance) * 1000}
        assert math.isclose(u, c["E"], rel_tol=1e-12), (u, c["E"])
        for target, current in expected.items():
            assert math.isclose(measured[target], current, rel_tol=1e-8), (measured, expected)
        assert math.isclose(measured[4], math.hypot(measured[1], measured[2] - measured[3]), rel_tol=1e-12)
        if tag == 1:
            assert measured[2] > measured[3]
        elif tag == 3:
            assert measured[3] > measured[2]
        if tag == 2:
            assert math.isclose(measured[2], measured[3], rel_tol=1e-12)
            assert math.isclose(measured[4], measured[1], rel_tol=1e-12)
        assert self.state["main_current"] == f"{expected[4]:.3f} mA", self.state
        labels = {1: "IR", 2: "IL", 3: "IC", 4: "I"}
        assert self.state["selected_current"] == f"{labels[2]} = {expected[2]:.3f} mA", self.state
        return measured, u

    def measurements(self, tag):
        self.click(f"B{9 + tag:02d}", "frequency")
        for index, target in enumerate((4, 1, 3, 2), 1):
            self.click(f"B{12 + target:02d}", "target")
            self.measure((tag - 1) * 4 + index)
        self.measure(tag * 4)  # a duplicate must not create a fifth measurement
        return self.point_readings(tag)

    def work(self):
        c = self.cfg
        f0 = 1 / (2 * math.pi * math.sqrt(c["L"] * c["C"]))
        self.snapshot("E01")
        self.press(1, 0)
        self.connect(WIRES, 8)
        self.remove("T10", "T12", 7)
        self.enter(1, 1, f0)
        self.press(1, 0)
        self.connect((("T12", "T10"),), 8)
        self.click("B01", "power")
        st = self.click("T01", "terminal")
        assert st["wire_count"] == 8 and not st["pending"], st
        self.click("B01", "power")
        self.enter(1, 1, "1+2")
        self.press(1, 0)
        assert "skai" in self.state["status"].lower(), self.state
        self.enter(1, 1, "999")
        self.press(2, 1)  # wrong physics is saved, not replaced by an answer
        self.click("OS_BACK", "back")
        assert str(flatten(self.state["answers"])[0]) == "999", self.state
        self.enter(1, 1, f0)
        self.press(2, 1)
        self.snapshot("E02")
        self.measure(0)  # no power
        self.click("B11", "frequency")  # wrong frequency for stage 2
        self.click("B13", "target")
        self.click("B01", "power")
        self.measure(0)  # open switch
        self.click("B02", "switch")
        self.measure(0)  # wrong frequency
        i1, u1 = self.measurements(1)
        self.press(3, 2)
        self.snapshot("E03")
        i0, _ = self.measurements(2)
        self.press(3, 2)  # two calculations are still missing
        self.input_values(3, [i0[2] / i0[4], i0[2] - i0[3]])
        self.press(4, 3)
        self.snapshot("E04")
        i2, _ = self.measurements(3)
        assert i0[4] < i1[4] and i0[4] < i2[4]
        self.press(5, 4)
        self.snapshot("E05")
        answers = [math.hypot(i1[1], i1[2] - i1[3]), i1[4] / u1,
                   i1[1] / i1[4], u1 * i1[1], u1 * (i1[2] - i1[3]), u1 * i1[4]]
        assert math.isclose(answers[3] ** 2 + answers[4] ** 2, answers[5] ** 2, rel_tol=1e-12)
        assert math.isclose(answers[2], answers[3] / answers[5], rel_tol=1e-12)
        self.input_values(5, answers)
        self.enter(5, 2, "1+2")
        self.press(5, 4)
        self.enter(5, 2, "999")
        self.press(6, 5)
        self.click("OS_BACK", "back")
        assert str(flatten(self.state["answers"])[1]) == "999", self.state
        self.enter(5, 2, answers[1])
        self.press(6, 5)
        self.snapshot("E06")
        self.press(6, 5)  # all three choices must be made
        self.choose(1, 2)
        self.choose(2, 1)
        self.choose(3, 1)
        self.press(6, 6)  # wrong but valid conclusion is preserved
        assert str(flatten(self.state["answers"])[0]) == "2", self.state
        self.choose(1, 1)
        self.press(6, 6)
        self.snapshot("E06-validated")
        self.click("B01", "power")
        self.click("OS_PRIMARY", "primary")

    def verify(self):
        assert self.state["done_count"] == 6 and self.state["journal_count"] == 12, self.state
        assert self.state["assessment"] and not self.state["practice"], self.state
        root = self.path / "Ataskaitos"
        reports = list(root.rglob("*.html"))
        assert len(reports) == 1, reports
        sys.path.insert(0, str(REPO / "core/tests"))
        from test_grading import run
        result, _ = run(self.args.grader.resolve(), root, self.path / "graded")
        graded = [r for r in result["results"] if r["file"].endswith(".html")]
        assert len(graded) == 1 and (graded[0]["points"], graded[0]["max_points"]) == (28, 28), graded
        assert graded[0]["selected_for_summary"] and graded[0]["rubric_version"] == "LD10-1", graded
        check = subprocess.run([str(self.args.checker.resolve()), str(self.path / "geometry_all.tsv")],
                               capture_output=True, text=True)
        (self.path / "geometry.log").write_text(check.stdout + check.stderr, encoding="utf-8")
        assert check.returncode == 0, check.stdout + check.stderr
        result = dict(status="PASS", lab="LD10", os=os.name, variant=17, stages=6,
                      circuit_wires=8, measurements=12, report_score="28/28",
                      geometry_scenarios=len(self.screen_files), screen_files=self.screen_files,
                      mouse_clicks=sum(x["kind"] == "real_OS_mouse" for x in self.events),
                      keyboard_entries=sum(x["kind"] == "real_OS_keyboard" for x in self.events),
                      independent_complex_admittance=True,
                      limitations="Fixed registration; real OS events in CI, not physical electrical equipment")
        (self.path / "acceptance.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print("LD10_NATIVE_PASS: " + json.dumps(result, ensure_ascii=False), flush=True)


def main():
    parser = argparse.ArgumentParser()
    for name in ("scilab", "core", "grader", "checker", "output"):
        parser.add_argument("--" + name, required=True, type=Path)
    args = parser.parse_args()
    lab = Lab10(argparse.Namespace(**vars(args), lab="LD10"))
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
