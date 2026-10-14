#!/usr/bin/env python3
"""End-to-end native LD6–LD8 student acceptance using OS mouse and keyboard.

Unlike Scilab callback tests, no user action is invoked through execstr,
and no student state is written by Python. GUI controls receive native
X11 XTest / Windows user32 pointer and keyboard events. Test-only Scilab
wrappers are READ-ONLY witnesses of callbacks that the OS actually caused.
This is desktop automation, not a claim of a physical human-held mouse.
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

REPO = Path(__file__).resolve().parents[1]
SCE = REPO / "tools" / "test_ld678_os_input.sce"
CODE = {"LD6": 4, "LD7": 3, "LD8": 3}


def cmd(*args, check=True):
    return subprocess.run([str(arg) for arg in args], check=check,
                          capture_output=True, text=True)


class Desktop:
    def __init__(self, lab, output):
        self.lab = lab
        self.output = output
        self.window = None
        self.client_origin = None
        self.client_size = None
        self.user = None
        if os.name == "nt":
            from ctypes import wintypes
            self.w = wintypes
            self.user = ctypes.windll.user32
            self.user.SetProcessDPIAware()
            # The Scilab canvas is 1280×720; on the default 1024×768 CI
            # desktop its right-hand primary button is beyond the viewport.
            # Use a real OS display-mode change, not a fictitious GUI click.
            self.ensure_desktop_resolution()
        else:
            cmd("xdotool", "--version")
            cmd("xwininfo", "-help", check=False)

    def ensure_desktop_resolution(self):
        width=self.user.GetSystemMetrics(0)
        height=self.user.GetSystemMetrics(1)
        if width>=1450 and height>=850:
            return
        import win32api
        import win32con
        modes=[]
        index=0
        while True:
            try:
                m=win32api.EnumDisplaySettings(None,index)
            except Exception:
                break
            if m.PelsWidth>=1450 and m.PelsHeight>=850:
                modes.append((m.PelsWidth,m.PelsHeight,m.BitsPerPel))
            index+=1
        # Prefer a regular 16:9 desktop, rather than an arbitrary very wide mode.
        modes.sort(key=lambda item:(abs(item[0]/item[1]-16/9),item[0]*item[1]))
        for w,h,_ in modes:
            setting=win32api.EnumDisplaySettings(None,win32con.ENUM_CURRENT_SETTINGS)
            setting.PelsWidth=w
            setting.PelsHeight=h
            if win32api.ChangeDisplaySettings(setting,0)==0:
                time.sleep(1)
                if self.user.GetSystemMetrics(0)>=1450 and self.user.GetSystemMetrics(1)>=850:
                    return
        raise RuntimeError(f"No desktop mode can show the full 1280x720 laboratory. "
                           f"Current Windows display {width}x{height}, modes={modes!r}")

    def locate(self):
        if os.name == "nt":
            found = []
            w, user = self.w, self.user
            @ctypes.WINFUNCTYPE(w.BOOL, w.HWND, w.LPARAM)
            def enum(hwnd, _):
                title = ctypes.create_unicode_buffer(512)
                user.GetWindowTextW(hwnd, title, len(title))
                if title.value == self.lab + " · OS INPUT TEST" and user.IsWindowVisible(hwnd):
                    found.append(hwnd)
                return True
            self.user.EnumWindows(enum, 0)
            if len(found) != 1:
                raise RuntimeError(f"{self.lab}: expected 1 visible native window, saw {len(found)}")
            self.window = found[0]
        else:
            ids = cmd("xdotool", "search", "--onlyvisible", "--name",
                      self.lab + " · OS INPUT TEST", check=False)
            if ids.returncode or not ids.stdout.strip():
                listing=cmd("xwininfo","-root","-tree",check=False)
                raise RuntimeError(f"{self.lab}: missing visible X11 window; "
                                   f"X root tree: {listing.stdout[-7000:]}; "
                                   f"stderr: {ids.stderr}; display={os.environ.get('DISPLAY')}")
            # Prefer the window whose actual title matches (not a child dialog).
            windows = ids.stdout.split()
            selected = []
            for wid in windows:
                title = cmd("xdotool", "getwindowname", wid, check=False)
                if title.returncode == 0 and self.lab + " · OS INPUT TEST" in title.stdout:
                    selected.append(wid)
            if len(selected) != 1:
                raise RuntimeError(f"Ambiguous X11 laboratory windows: {selected!r}")
            self.window = selected[0]
        self.update_origin()

    def update_origin(self):
        if os.name == "nt":
            w = self.w
            rect = w.RECT()
            point = w.POINT(0, 0)
            assert self.user.GetClientRect(self.window, ctypes.byref(rect))
            assert self.user.ClientToScreen(self.window, ctypes.byref(point))
            self.client_origin = (point.x, point.y)
            self.client_size = (rect.right, rect.bottom)
            self.user.SetForegroundWindow(self.window)
        else:
            output = cmd("xwininfo", "-id", self.window).stdout
            values = {}
            for name, pattern in {
                "x": r"Absolute upper-left X:\s*(-?\d+)",
                "y": r"Absolute upper-left Y:\s*(-?\d+)",
                "w": r"Width:\s*(\d+)",
                "h": r"Height:\s*(\d+)"
            }.items():
                match = re.search(pattern, output)
                if not match:
                    raise RuntimeError("Cannot read native X11 client geometry: " + output)
                values[name] = int(match.group(1))
            self.client_origin = (values["x"], values["y"])
            self.client_size = (values["w"], values["h"])
            cmd("xdotool", "windowfocus", self.window, check=False)

    def click_xy(self, x, y):
        if os.name == "nt":
            if not self.user.SetCursorPos(x, y):
                raise RuntimeError(f"SetCursorPos failed at {x},{y}")
            self.user.mouse_event(0x0002, 0, 0, 0, 0)  # left down
            time.sleep(.045)
            self.user.mouse_event(0x0004, 0, 0, 0, 0)  # left up
        else:
            cmd("xdotool", "mousemove", "--sync", x, y)
            cmd("xdotool", "click", "--clearmodifiers", "1")

    def key(self, name):
        if os.name != "nt":
            cmd("xdotool", "key", "--clearmodifiers", name)
            return
        aliases = {"Home": 0x24, "Down": 0x28, "Return": 0x0D,
                   "Tab": 0x09, "BackSpace": 0x08, "Delete": 0x2E}
        if name == "ctrl+a":
            self.user.keybd_event(0x11, 0, 0, 0)
            self.user.keybd_event(0x41, 0, 0, 0)
            self.user.keybd_event(0x41, 0, 2, 0)
            self.user.keybd_event(0x11, 0, 2, 0)
            return
        code = aliases[name]
        self.user.keybd_event(code, 0, 0, 0)
        self.user.keybd_event(code, 0, 2, 0)

    def type_text(self, content):
        if os.name != "nt":
            cmd("xdotool", "type", "--clearmodifiers", "--delay", "8", str(content))
            return
        for char in str(content):
            vk = self.user.VkKeyScanW(ord(char))
            if vk == -1:
                raise RuntimeError("Cannot type " + repr(char))
            code, shift = vk & 0xFF, (vk >> 8) & 1
            if shift:
                self.user.keybd_event(0x10, 0, 0, 0)
            self.user.keybd_event(code, 0, 0, 0)
            self.user.keybd_event(code, 0, 2, 0)
            if shift:
                self.user.keybd_event(0x10, 0, 2, 0)
            time.sleep(.013)


class Lab:
    def __init__(self, lab, root, binary):
        self.lab = lab
        self.path = root / lab
        self.path.mkdir(parents=True)
        self.desktop = Desktop(lab, self.path)
        self.proc = None
        self.seq = -1
        self.actions = []
        self.env = dict(os.environ, OS_INPUT_LAB=lab,
                        OS_INPUT_SOURCE=REPO.as_posix(),
                        OS_INPUT_OUT=self.path.as_posix(),
                        LD_DATA_DIR=(self.path / "Studento ataskaitos").as_posix())
        self.env["LD_CORE_LIBRARY"] = str(binary.resolve())
        self.state_file = self.path / "state.json"

    def start(self, scilab):
        exe = scilab.resolve()
        if os.name == "nt":
            exe = exe.parent / "WScilex.exe"
        command = [str(exe)]
        if os.name != "nt":
            command += ["-nw"]
        command += ["-nb", "-scihome", str(self.path / "scihome"),
                    "-f", str(SCE)]
        (self.path / "scihome").mkdir(exist_ok=True)
        self.log = (self.path / "scilab.log").open("wb")
        self.proc = subprocess.Popen(command, stdin=subprocess.PIPE,
                                     stdout=self.log, stderr=subprocess.STDOUT,
                                     env=self.env, start_new_session=(os.name!="nt"))
        self.wait_file("ready", 90)
        self.config = json.loads((self.path / "config.json").read_text(encoding="utf-8"))
        self.wires = {}
        for row in (self.path / "wires.tsv").read_text(encoding="utf-8").splitlines():
            mode, a, b = row.split("\t")
            self.wires.setdefault(int(mode), []).append((a, b))
        deadline = time.monotonic() + 25
        while True:
            try:
                self.desktop.locate()
                break
            except (RuntimeError, subprocess.CalledProcessError):
                if self.proc.poll() is not None:
                    raise RuntimeError(f"{self.lab}: Scilab exited before the desktop window became visible; "
                                       f"returncode={self.proc.returncode}")
                if time.monotonic() > deadline:
                    raise
                time.sleep(.25)
        state = self.wait_state(-1, "ready")
        assert state["step"] == 1 and state["wire_count"] == 0, state
        assert len(self.wires) == CODE[self.lab] and all(len(v)>0 for v in self.wires.values())
        self.actions.append({"action": "opened_real_window", "client": self.desktop.client_size})

    def wait_file(self, name, timeout):
        deadline = time.monotonic() + timeout
        while not (self.path / name).is_file():
            if (self.path / "failure").is_file():
                raise RuntimeError((self.path / "failure").read_text(encoding="utf-8"))
            if self.proc.poll() is not None:
                raise RuntimeError(f"Scilab exited with code {self.proc.returncode}")
            if time.monotonic() > deadline:
                log = (self.path / "scilab.log").read_text(encoding="utf-8", errors="replace")
                raise TimeoutError(f"{self.lab}: waiting for {name}\n{log[-6000:]}")
            time.sleep(.15)

    def wait_state(self, previous, event, timeout=25):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            try:
                state = json.loads(self.state_file.read_text(encoding="utf-8"))
                if int(state["seq"]) > previous and state["event"] == event:
                    self.seq = int(state["seq"])
                    self.state = state
                    return state
            except (OSError, ValueError, KeyError, TypeError):
                pass
            if (self.path / "failure").exists():
                raise RuntimeError((self.path / "failure").read_text(encoding="utf-8"))
            if self.proc.poll() is not None:
                raise RuntimeError(f"Scilab exited during {event}")
            time.sleep(.09)
        log = (self.path / "scilab.log").read_text(encoding="utf-8", errors="replace")
        raise TimeoutError(f"{self.lab}: no native callback {event} after seq {previous}; "
                           f"last state={getattr(self,'state',None)}\n{log[-8000:]}")

    def location(self, tag, style=None):
        rows = [line.split("\t") for line in
                (self.path / "geometry.tsv").read_text(encoding="utf-8").splitlines()]
        rows = [r for r in rows if len(r) >= 8 and r[3] == tag
                and (style is None or r[2] == style)]
        if len(rows) != 1:
            raise AssertionError(f"{self.lab}: {tag} not uniquely visible. {rows!r}")
        rect = [float(q) for q in rows[0][4:8]]
        x,y,width,height=rect
        # Geometry TSV uses bottom-left Scilab client coordinates. OS mouse
        # coordinates use upper-left native screen coordinates.
        self.desktop.update_origin()
        ox, oy = self.desktop.client_origin
        _, client_h = self.desktop.client_size
        target=(round(ox+x+width/2),round(oy+client_h-y-height/2))
        if not (ox <= target[0] < ox+self.desktop.client_size[0] and
                oy <= target[1] < oy+client_h):
            raise AssertionError(f"{tag}: target {target} outside real client. "
                                 f"origin={self.desktop.client_origin},size={self.desktop.client_size}, "
                                 f"rectangle={rect}. Requires actual OS scrolling or a larger screen.")
        return target

    def click(self, tag, event, expected_step=None):
        x,y = self.location(tag, "pushbutton")
        prev = self.seq
        self.desktop.click_xy(x,y)
        state = self.wait_state(prev, event)
        if expected_step is not None and int(state["step"]) != expected_step:
            raise AssertionError(f"{self.lab} {tag}: expected step {expected_step}, got {state}")
        self.actions.append({"action":"mouse_click","tag":tag,"event":event,"at":[x,y],
                             "step":state["step"],"journal":state["journal"]})
        return state

    def type_answer(self, step, slot, value):
        tag=f"A{step:02d}.{slot:02d}"
        x,y=self.location(tag,"edit")
        self.desktop.click_xy(x,y)
        self.desktop.key("ctrl+a")
        self.desktop.type_text(f"{float(value):.10g}" if not isinstance(value,str) else value)
        self.desktop.key("Tab")
        self.actions.append({"action":"keyboard_input","tag":tag,"value":str(value)})

    def choose_yes(self, step, slot):
        tag=f"A{step:02d}.{slot:02d}"
        x,y=self.location(tag,"popupmenu")
        self.desktop.click_xy(x,y)
        self.desktop.key("Home")
        self.desktop.key("Down")
        self.desktop.key("Return")
        self.actions.append({"action":"native_dropdown","tag":tag})

    def connect(self, mode):
        assert int(self.state["wire_count"]) == 0, self.state
        for index,(first,second) in enumerate(self.wires[mode]):
            self.click(first, "terminal")
            second_state = self.click(second, "terminal")
            assert second_state["wire_count"] == index+1, (mode,index,second_state)
            assert second_state["pending"] == "", second_state
        self.actions.append({"action":"completed_real_wiring","mode":mode,
                             "wire_count":len(self.wires[mode])})

    def measure(self, *, switch=True):
        s=self.click("B01","power")
        assert s["power"],s
        if switch:
            s=self.click("B02","switch")
            assert s["switch"],s
        before=int(s["journal"])
        s=self.click("B03","measure")
        assert s["journal"]==before+1, (self.lab,before,s)
        s=self.click("B01","power")
        assert not s["power"],s
        self.actions.append({"action":"instrument_measured","journal":s["journal"]})

    def advance(self, after):
        s=self.click("OS_PRIMARY","primary",expected_step=after)
        if after < 6:
            assert int(s["done_count"])>=after-1,s
        return s

    def submit(self):
        s=self.click("OS_PRIMARY","primary",expected_step=6)
        assert int(s["done_count"])==6,s
        deadline=time.monotonic()+15
        root=self.path/"Studento ataskaitos"
        while time.monotonic()<deadline:
            files=list(root.rglob("*.html")) if root.exists() else []
            if files:
                self.actions.append({"action":"actual_html_export","files":[f.name for f in files]})
                return files
            time.sleep(.2)
        raise AssertionError(f"{self.lab}: no HTML report after actual final button click")

    def work(self):
        c=self.config
        if self.lab=="LD6":
            self.connect(1)
            self.advance(2)
            self.measure()
            self.type_answer(2,1,c["E1"]/(c["R"]+c["r1"])*1000)
            self.advance(3)
            self.connect(2)
            self.measure()
            self.advance(4)
            self.connect(3)
            self.measure()
            self.type_answer(4,1,c["E1"]+c["E2"])
            self.type_answer(4,2,c["E1"]-c["E2"])
            self.advance(5)
            self.connect(4)
            self.measure()
            eeq=(c["E1"]/c["r1"]+c["E2"]/c["r2"])/(1/c["r1"]+1/c["r2"])
            req=1/(1/c["r1"]+1/c["r2"])
            self.type_answer(5,1,eeq);self.type_answer(5,2,req)
            self.advance(6)
            self.type_answer(6,1,1);self.type_answer(6,2,2)
        elif self.lab=="LD7":
            self.connect(1)
            self.advance(2)
            s=self.click("B01","power"); assert s["power"]
            s=self.click("B02","switch"); assert s["switch"]
            for mode in range(1,6):
                self.click(f"B{12+mode:02d}","position")
                s=self.click("B03","measure")
                assert s["journal"]==mode,s
            self.click("B01","power")
            self.advance(3)
            r=c["r"]; E=c["E"]; loads=[c[f"R{i}"] for i in range(1,6)]
            U1=E*loads[0]/(loads[0]+r)
            self.type_answer(3,1,r)
            self.type_answer(3,2,E-U1)
            self.advance(4)
            U3=E*loads[2]/(loads[2]+r)
            I3=1000*E/(loads[2]+r)
            self.type_answer(4,1,U3*I3)
            self.type_answer(4,2,1000*E*E/(4*r))
            self.type_answer(4,3,50)
            self.advance(5)
            assert int(self.state["mode"])==2
            self.connect(2)
            self.measure(switch=False)
            self.click("B12","mode")
            self.connect(3)
            self.measure()
            self.advance(6)
            for k in range(1,4):self.choose_yes(6,k)
        elif self.lab=="LD8":
            self.connect(1)
            self.measure()
            self.advance(2)
            R1,R2,R3=(c["R1"],c["R2"],c["R3"])
            E=c["E"]
            self.type_answer(2,1,R1+R2+R3)
            self.advance(3)
            self.connect(2)
            self.measure()
            self.type_answer(3,1,1/(1/R1+1/R2+1/R3))
            self.advance(4)
            self.connect(3)
            self.measure()
            self.type_answer(4,1,R1+R2*R3/(R2+R3))
            self.advance(5)
            for i,R in enumerate([R1,R2,R3],start=1):
                self.type_answer(5,i,1000*E/R)
            self.advance(6)
            for k in range(1,4):self.choose_yes(6,k)
        else:
            raise AssertionError(self.lab)
        s=self.click("OS_PRIMARY","primary",expected_step=6)
        assert int(s["done_count"])==6,s
        assert s["journal"]=={"LD6":4,"LD7":7,"LD8":3}[self.lab],s
        assert s["power"] is False
        files=self.submit()
        self.actions.append({"action":"all_six_stages_verified","total_actions":len(self.actions)})
        return files

    def shutdown(self):
        try:
            if self.proc is not None and self.proc.poll() is None:
                # Scilab's Linux wrapper may signal its entire process group
                # on SIGTERM. Never signal the GitHub runner's process group.
                if self.proc.stdin:
                    try:
                        self.proc.stdin.write(b"exit(0)\n")
                        self.proc.stdin.flush()
                        self.proc.wait(timeout=4)
                    except (BrokenPipeError, OSError, subprocess.TimeoutExpired):
                        pass
                if self.proc.poll() is None:
                    self.proc.terminate()
                    try:
                        self.proc.wait(timeout=10)
                    except subprocess.TimeoutExpired:
                        self.proc.kill()
                        self.proc.wait(timeout=5)
        finally:
            if hasattr(self,"log"):
                self.log.close()


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--scilab",type=Path,required=True)
    p.add_argument("--core",type=Path,required=True)
    p.add_argument("--output",type=Path,required=True)
    p.add_argument("--labs",nargs="+",choices=["LD6","LD7","LD8"],default=["LD6","LD7","LD8"])
    args=p.parse_args()
    out=args.output.resolve();out.mkdir(parents=True,exist_ok=True)
    summaries=[]
    for lab in args.labs:
        test=Lab(lab,out,args.core)
        try:
            test.start(args.scilab)
            reports=test.work()
            summary={"lab":lab,"status":"PASS","native_os":os.name,"variant":17,
                     "stages":6,"terminal_pairs":sum(len(w) for w in test.wires.values()),
                     "native_mouse_events":sum(a["action"]=="mouse_click" for a in test.actions),
                     "native_keyboard_fields":sum(a["action"]=="keyboard_input" for a in test.actions),
                     "html_reports":len(reports),"interaction_log":test.actions,
                     "caveat":"OS-injected desktop events, not a physical hand-operated mouse"}
            (test.path/"acceptance.json").write_text(json.dumps(summary,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
            summaries.append({k:v for k,v in summary.items() if k!="interaction_log"})
            print(json.dumps(summaries[-1],ensure_ascii=False),flush=True)
        except Exception as error:
            (test.path/"failure.txt").write_text(str(error)+"\n",encoding="utf-8")
            raise
        finally:
            test.shutdown()
    (out/"acceptance.json").write_text(json.dumps(summaries,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    print("OS_REAL_INPUT_PASS: "+json.dumps(summaries,ensure_ascii=False),flush=True)


if __name__=="__main__":
    main()
