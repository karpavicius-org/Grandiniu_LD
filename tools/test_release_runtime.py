#!/usr/bin/env python3
"""Local Linux release smoke: independently predicted circuit values and teacher CLI."""
import ctypes as c
import math
import os
from pathlib import Path
import subprocess
import tempfile
import zipfile
import argparse


def close(got, expected, label):
    assert math.isclose(got, expected, rel_tol=2e-7, abs_tol=2e-7), (label, got, expected)


def run(archive: Path):
    with tempfile.TemporaryDirectory(prefix='grandiniu-runtime-') as t:
        root = Path(t)
        with zipfile.ZipFile(archive) as z:
            z.extractall(root)
        folder = root/'Grandiniu_LD'
        binary = folder/'bin'
        for exe in ['ldcheck', 'mokytojas']:
            (binary/exe).chmod(0o755)
        lib = c.CDLL(str(binary/'ldcore.so'))
        lib.ld_sources.argtypes = [c.POINTER(c.c_int), c.POINTER(c.c_double),c.POINTER(c.c_double),c.POINTER(c.c_int)]
        for mode in (1, 4, 9):
            m=c.c_int(mode); v=(c.c_double*5)(10,5,9,1,1)
            out=(c.c_double*4)(); s=c.c_int(-1)
            lib.ld_sources(c.byref(m),v,out,c.byref(s))
            if mode==1:
                assert s.value==0
                for x,expected,label in zip(out,[9,1000,1000,0],['volts','mA','mA','mA']):close(x,expected,label)
            elif mode==4:
                # Kirchhoff: V/9 + (V-10)/1 + (V-5)/1 = 0.
                volts = 15/(2+1/9)
                assert s.value==0
                for x,expected,label in zip(out,[volts,volts/9*1000,(10-volts)*1000,(5-volts)*1000],['V','mA load','mA E1','mA E2']):close(x,expected,label)
            else:
                assert s.value!=0
        lib.ld_ac.argtypes=[c.POINTER(c.c_int),c.POINTER(c.c_double),c.POINTER(c.c_double),c.POINTER(c.c_int)]
        mode=c.c_int(6); v=(c.c_double*5)(math.sqrt(3)*10,50,10,0,0)
        out=(c.c_double*10)();s=c.c_int(-1)
        lib.ld_ac(c.byref(mode),v,out,c.byref(s))
        assert s.value==0
        # Star: U_phase=10 V, I_phase=1 A, P=30 W;
        # delta: U_phase=10sqrt(3) V, I_phase=sqrt(3) A, P=90 W.
        for got,expected in zip(out,[10,1000,math.sqrt(3)*10,math.sqrt(3)*1000,3000,30,90,math.sqrt(3)*10,0,0]):close(got,expected,'Y-delta')
        source = root/'samples';source.mkdir()
        output = root/'graded'
        p=subprocess.run([str(binary/'ldcheck'), str(source), str(output)], capture_output=True, text=True, timeout=20)
        assert p.returncode==0, (p.returncode,p.stdout,p.stderr)
        assert (output/'vertinimai.html').exists() and (output/'suvestine.csv').exists() and (output/'vertinimai.json').exists(), list(output.iterdir())
        # Teacher application must retain its own C++ report-processing logic.
        work=root/'teacher-work';work.mkdir()
        proc=subprocess.run([str(binary/'mokytojas'),str(source)],cwd=work,capture_output=True,text=True, timeout=20,
                            env={**os.environ,'MOKYTOJAS_NO_BROWSER':'1'})
        assert proc.returncode==0,(proc.returncode,proc.stdout,proc.stderr)
        assert (work/'IVERTINIMAI.csv').exists() and (work/'ZURNALAS.csv').exists(),list(work.iterdir())
        print('PASS: real ldcore FFI DC+3-phase independent expected values; negative mode; ldcheck writes 3 reports; mokytojas writes 2 journals')

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('archive',type=Path);run(p.parse_args().archive)
