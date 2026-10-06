"""Capture only a named laboratory window for visual verification."""
import os
import re
import subprocess
import sys

if os.name == 'nt':
    import ctypes as c
    from ctypes import wintypes as w
    from PIL import ImageGrab
    prefix, output = sys.argv[1:]
    user = c.windll.user32
    user.SetProcessDPIAware()
    found = []
    @c.WINFUNCTYPE(w.BOOL, w.HWND, w.LPARAM)
    def visit(hwnd, _):
        title = c.create_unicode_buffer(1024)
        user.GetWindowTextW(hwnd, title, len(title))
        if title.value.startswith(prefix) and user.IsWindowVisible(hwnd):
            found.append(hwnd)
        return True
    user.EnumWindows(visit, 0)
    if not found:
        raise SystemExit(f'No laboratory window starts with {prefix!r}')
    user.SetForegroundWindow(found[0])
    import time
    time.sleep(.3)
    rect = w.RECT()
    user.GetWindowRect(found[0], c.byref(rect))
    ImageGrab.grab(bbox=(rect.left, rect.top, rect.right, rect.bottom)).save(output)
    print(output, rect.right-rect.left, rect.bottom-rect.top)
    raise SystemExit(0)

os.environ["GDK_BACKEND"] = "x11"
import gi
gi.require_version("Gdk", "3.0")
gi.require_version("GdkX11", "3.0")
from gi.repository import Gdk, GdkX11

prefix, output = sys.argv[1:]
tree = subprocess.check_output(["xwininfo", "-root", "-tree"], text=True)
matches = [line for line in tree.splitlines()
           if f'"{prefix}' in line and '("Scilab" "Scilab")' in line]
if not matches:
    raise SystemExit(f"No laboratory window starts with {prefix!r}")
xid = int(re.search(r"0x[0-9a-fA-F]+", matches[0]).group(), 16)
display = Gdk.Display.get_default()
window = GdkX11.X11Window.foreign_new_for_display(display, xid)
pixbuf = Gdk.pixbuf_get_from_window(window, 0, 0, window.get_width(), window.get_height())
if pixbuf is None:
    raise SystemExit("The laboratory window could not be captured")
pixbuf.savev(output, "png", [], [])
print(output, pixbuf.get_width(), pixbuf.get_height())
