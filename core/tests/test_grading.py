#!/usr/bin/env python3
"""Independent analytical fixtures, complete batch + adversarial import tests."""
import copy
import csv
import ctypes
import json
import math
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time

START = '<script type="application/json" id="ld-data">'

def fixture(lab, n, identity):
    a, b = divmod(n - 1, 8)
    dc = [330, 470, 680, 820, 1000, 1200, 1500, 2200]
    r1, r2, r3 = dc[a], dc[b], dc[(a + b) % 8]
    r8 = [330, 470, 680, 820, 1000, 1200, 1500, 1800][a]
    r9 = [100, 150, 180, 220, 270, 330, 390, 470][b]
    l = [10, 12, 15, 18, 22, 27, 33, 39][a] * .001
    c = [47, 56, 68, 82, 100, 120, 150, 180][b] * 1e-9
    r13 = math.floor(math.sqrt(l / c) / (2.8 + .35 * (a + 1) + .20 * (b + 1)) + .5)
    frc, frl = 35 + 5 * (b + 1), 35 + 5 * (a + 1)
    report = dict(schema_version=1, lab_id=lab, lab_revision="1", rubric_version=lab + "-1",
                  bank_id=lab + "-64-A-2026", variant=n, submission_id=f"test-{identity}",
                  mode="assessment", student=dict(number=n, name=f"Žąsė Ąžuolas {identity}", group="EG-1"),
                  parameters={}, answers=[], observations=[], evidence={}, note="")
    def answer(step, q, value, unit):
        report["answers"].append(dict(id=f"s{step}.{q}", raw=format(value, ".12g"), unit=unit))
    def observation(key, value, unit):
        report["observations"].append(dict(id=key, value=value, unit=unit))
    def vector(step, values, units):
        for q, (value, unit) in enumerate(zip(values, units), 1):
            answer(step, "q" + str(q), value, unit)
    if lab == "LD1":
        report["parameters"] = dict(E=10, R1=r1, R2=r2, R3=r3)
        for step, vr in [(2, 1000), (4, 500)]:
            vector(step, [r1 + vr, 10000 / (r1 + vr)], ["Ohm", "mA"])
        vector(6, [r3 * (r2 + 1000) / (r3 + r2 + 1000)], ["Ohm"])
        vector(8, [10000/r3, 10000/r2, 10000/r3 + 10000/r2], ["mA"] * 3)
        answer(1, "type", 1, "choice"); answer(5, "type", 2, "choice")
        for step, value, unit in [(3, 10000/(r1+1000), "mA"), (4, 10000/(r1+500), "mA"),
                                  (6, 10, "V"), (7, 10, "V"), (8, 10000/r3+10000/r2, "mA")]:
            answer(step, "compare", 2 if step == 7 else 1, "choice")
            observation(f"s{step}.measure", value, unit)
        report["evidence"] = dict(realistic=False, wiring={
            "s1": dict(meter="A", pairs=[["SRC_P","R1_1"],["R1_2","VR1_1"],["VR1_2","M_P"],["M_N","SRC_N"]]),
            "s5": dict(meter="V", pairs=[["SRC_P","NODE_A1"],["SRC_N","NODE_B1"],
                ["NODE_A2","R3_1"],["R3_2","NODE_B2"],["NODE_A3","R2_1"],["R2_2","VR1_1"],
                ["VR1_2","NODE_B3"],["M_P","NODE_A4"],["M_N","NODE_B4"]])})
    elif lab == "LD3":
        rr = [33, 47, 56, 68, 82, 100, 120, 150][a]
        u1_, u2_, u3_ = [(3, 6, 9), (4, 8, 12), (2, 5, 8), (5, 10, 12),
                         (3, 7, 11), (6, 9, 12), (2, 6, 10), (4, 7, 10)][b]
        report["parameters"] = dict(R=rr, U1=u1_, U2=u2_, U3=u3_)
        vector(2, [u1_ / rr * 1000], ["mA"])
        for k, u in [(1, u1_), (2, u2_), (3, u3_)]:
            observation(f"u{k}", u, "V")
            observation(f"i{k}", u / rr * 1000, "mA")
        vector(4, [rr, rr, rr, rr], ["Ohm"] * 4)
        vector(5, [rr], ["Ohm"])
        vector(6, [1, 1], ["choice", "choice"])
        report["evidence"] = dict(wiring={"s1": [["E_P", "K1"], ["K2", "A_P"], ["A_N", "R1A"],
                                          ["R1B", "E_N"], ["V_P", "R1A"], ["V_N", "R1B"]]})
    elif lab == "LD4":
        n1_ = [100, 120, 150, 180, 220, 270, 330, 390][a]
        n2_ = [470, 560, 680, 820, 1000, 1200, 1500, 1800][b]
        d1 = n % 11 - 5
        d2 = (3 * n) % 11 - 5
        r1a_ = round(n1_ * (1 + d1 / 100) * 10) / 10
        r2a_ = round(n2_ * (1 + d2 / 100) * 10) / 10
        u1_, u2_, u3_ = [(3, 6, 9), (4, 8, 12), (2, 5, 8), (5, 10, 12),
                         (3, 7, 11), (6, 9, 12), (2, 6, 10), (4, 7, 10)][b]
        report["parameters"] = dict(R1nom=n1_, R2nom=n2_, R1=r1a_, R2=r2a_, U1=u1_, U2=u2_, U3=u3_)
        vector(2, [u1_ / n1_ * 1000], ["mA"])
        for tag, rr in [(1, r1a_), (2, r2a_)]:
            for k, u in [(1, u1_), (2, u2_), (3, u3_)]:
                observation(f"r{tag}u{k}", u, "V")
                observation(f"r{tag}i{k}", u / rr * 1000, "mA")
        observation("su1", u3_, "V")
        observation("si1", u3_ / (r1a_ + r2a_) * 1000, "mA")
        r1m = r1a_; r2m = r2a_
        vector(4, [r1m, r2m, (r1m / n1_ - 1) * 100, (r2m / n2_ - 1) * 100], ["Ohm", "Ohm", "1", "1"])
        vector(5, [r1a_, r2a_, 1000 / r2a_], ["Ohm", "Ohm", "mS"])
        vector(6, [r1a_ + r2a_], ["Ohm"])
        vector(7, [1, 1], ["choice", "choice"])
        series = [["E_P", "K1"], ["K2", "A_P"], ["A_N", "R1A"], ["R1B", "R2A"],
                  ["R2B", "E_N"], ["V_P", "R1A"], ["V_N", "R2B"]]
        report["evidence"] = dict(wiring={"s1": {"pairs": [["E_P","K1"],["K2","A_P"],["A_N","R1A"],["R1B","E_N"],["V_P","R1A"],["V_N","R1B"]], "meter": "DC"},
                                          "s6": {"pairs": series, "meter": "DC"}})
    elif lab == "LD5":
        n1_ = [100, 120, 150, 180, 220, 270, 330, 390][a]
        n2_ = [470, 560, 680, 820, 1000, 1200, 1500, 1800][b]
        d1 = n % 11 - 5
        d2 = (3 * n) % 11 - 5
        r1a_ = round(n1_ * (1 + d1 / 100) * 10) / 10
        rva_ = round(n2_ * (1 + d2 / 100) * 10) / 10
        p1_, p2_, p3_ = [(25, 50, 75), (20, 45, 70), (30, 55, 80), (15, 40, 65),
                          (35, 60, 85), (25, 60, 90), (10, 50, 80), (30, 50, 70)][b]
        report["parameters"] = dict(R1nom=n1_, RVnom=n2_, R1=r1a_, RV=rva_, E=9, P1=p1_, P2=p2_, P3=p3_)
        rv2 = rva_ * p2_ / 100
        rv1 = rva_ * p1_ / 100
        rv3 = rva_ * p3_ / 100
        u1_, u2_, u3_ = 9*rv1/(r1a_+rv1), 9*rv2/(r1a_+rv2), 9*rv3/(r1a_+rv3)
        vector(2, [u2_], ["V"])
        for k, u in [(1, u1_), (2, u2_), (3, u3_)]:
            observation(f"u{k}", u, "V")
            observation(f"i{k}", 9/(r1a_ + [rv1, rv2, rv3][k-1]) * 1000, "mA")
        vector(4, [u1_, u3_, u3_ - u1_, (u3_ - u1_) / 9 * 100], ["V", "V", "V", "1"])
        vector(5, [9/(r1a_+rv2)*1000, rv2/(r1a_+rv2)*100], ["mA", "1"])
        vector(6, [1, 1], ["choice", "choice"])
        series = [["E_P", "K1"], ["K2", "A_P"], ["A_N", "R1A"], ["R1B", "RVA"],
                  ["RVB", "E_N"], ["V_P", "RVA"], ["V_N", "RVB"]]
        report["evidence"] = dict(wiring={"s1": {"pairs": series, "meter": "DC"}})
    elif lab == "LD6":
        e2_ = [3, 4, 5, 6, 7, 8, 10, 12][b]
        r6n_ = [100, 120, 150, 180, 220, 270, 330, 390][a]
        d6 = ((n * 5) % 11) - 5
        r6_ = round(r6n_ * (1 + d6 / 100) * 10) / 10
        report["parameters"] = dict(E1=9, E2=e2_, R=r6_, Rnom=r6n_)
        vector(2, [9 / r6_ * 1000], ["mA"])
        for k, (u_, i_) in enumerate([(9, 9/r6_*1000), (9+e2_, (9+e2_)/r6_*1000), (9-e2_, (9-e2_)/r6_*1000)]):
            observation(f"u{k+1}", u_, "V")
            observation(f"i{k+1}", i_, "mA")
        vector(4, [9+e2_, (9+e2_)/r6_*1000, 9-e2_, (9-e2_)/r6_*1000], ["V", "mA", "V", "mA"])
        vector(6, [1, 1], ["choice", "choice"])
        series = [["E1_P", "K1"], ["K2", "A_P"], ["A_N", "R_A"], ["R_B", "E1_N"],
                  ["V_P", "R_A"], ["V_N", "R_B"]]
        report["evidence"] = dict(wiring={"s1": {"pairs": series, "meter": "DC"}})
    elif lab == "LD7":
        e7_ = [3, 4, 5, 6, 7, 8, 10, 12][b]
        r7_ = [22, 27, 33, 39, 47, 56, 68, 82][a]
        m7 = [0.33, 0.56, 1.0, 1.8, 3.0]
        load = [round(k * r7_ * 10) / 10 for k in m7]
        report["parameters"] = dict(E=e7_, r=r7_, **{f"R{k + 1}": v for k, v in enumerate(load)})
        for k, rr in enumerate(load):
            observation(f"u{k + 1}", e7_ * rr / (rr + r7_), "V")
            observation(f"i{k + 1}", e7_ / (rr + r7_) * 1000, "mA")
        observation("te_u", e7_ * 1e6 / (1e6 + r7_), "V")
        observation("tj_i", e7_ / (r7_ + 1e-6) * 1000, "mA")
        vector(3, [r7_, e7_], ["Ohm", "V"])
        vector(4, [e7_ * load[0] / (load[0] + r7_) * e7_ / (load[0] + r7_) * 1000,
                   e7_ * load[2] / (load[2] + r7_) * e7_ / (load[2] + r7_) * 1000,
                   e7_ * load[4] / (load[4] + r7_) * e7_ / (load[4] + r7_) * 1000,
                   1000 * e7_ * e7_ / (4 * r7_), 50.0], ["mW", "mW", "mW", "mW", "1"])
        vector(5, [e7_ * 1e6 / (1e6 + r7_), e7_ / r7_ * 1000], ["V", "mA"])
        vector(6, [1, 1, 1], ["choice", "choice", "choice"])
        report["evidence"] = dict(wiring={
            "s1": {"pairs": [["E_P", "K1"], ["K2", "A_P"], ["A_N", "R_A"], ["R_B", "E_N"],
                             ["V_P", "R_A"], ["V_N", "R_B"]], "meter": "DC"},
            "s5te": {"pairs": [["V_P", "E_P"], ["V_N", "E_N"]], "meter": "DC"},
            "s5tj": {"pairs": [["E_P", "K1"], ["K2", "A_P"], ["A_N", "E_N"]], "meter": "DC"}})
    elif lab == "LD8":
        a8 = round([100, 120, 150, 180, 220, 270, 330, 390][a] * (1 + (n % 11 - 5) / 100) * 10) / 10
        b8 = round([470, 560, 680, 820, 1000, 1200, 1500, 1800][b] * (1 + ((3 * n) % 11 - 5) / 100) * 10) / 10
        c8 = round([220, 270, 330, 390, 470, 560, 680, 820][(a + b) % 8] * (1 + ((5 * n) % 11 - 5) / 100) * 10) / 10
        report["parameters"] = dict(E=12, R1=a8, R2=b8, R3=c8)
        series = a8 + b8 + c8
        parallel = 1 / (1 / a8 + 1 / b8 + 1 / c8)
        mixed = a8 + b8 * c8 / (b8 + c8)
        for k, rr in [(1, series), (2, parallel), (3, mixed)]:
            observation(f"u{k}", 12, "V")
            observation(f"i{k}", 12 / rr * 1000, "mA")
        vector(2, [series, series], ["Ohm", "Ohm"])
        vector(3, [parallel, parallel], ["Ohm", "Ohm"])
        vector(4, [mixed, mixed], ["Ohm", "Ohm"])
        vector(5, [12 / a8 * 1000, 12 / b8 * 1000, 12 / c8 * 1000], ["mA"] * 3)
        vector(6, [1, 1, 1], ["choice", "choice", "choice"])
        base = [["E_P", "K1"], ["K2", "A_P"], ["A_N", "R1_A"], ["V_P", "E_P"], ["V_N", "E_N"]]
        wirings = {1: base + [["R1_B", "R2_A"], ["R2_B", "R3_A"], ["R3_B", "E_N"]],
                   3: base + [["R1_A", "R2_A"], ["R2_A", "R3_A"], ["R1_B", "E_N"], ["R1_B", "R2_B"], ["R2_B", "R3_B"]],
                   4: base + [["R1_B", "R2_A"], ["R2_A", "R3_A"], ["R2_B", "R3_B"], ["R3_B", "E_N"]]}
        report["evidence"] = dict(wiring={f"s{stage}": dict(pairs=copy.deepcopy(wirings[stage]), meter="DC")
                                        for stage in [1, 3, 4]})
    elif lab == "LD9":
        import math as m9
        l9_ = [10, 12, 15, 18, 22, 27, 33, 39][a] * 1e-3
        c9_ = [47, 56, 68, 82, 100, 120, 150, 180][b] * 1e-9
        qt = 2.0 + 0.5 * ((a + b) % 4)
        r9_ = round(100 * m9.sqrt(l9_ / c9_) / qt) / 100
        report["parameters"] = dict(E=5, R=r9_, L=l9_, C=c9_)
        f0 = 1 / (2 * m9.pi * m9.sqrt(l9_ * c9_))
        z = m9.hypot(r9_, 0)  # pakaitas; realias reikšmes skaičiuoja ld::ac
        for point, k in enumerate([0.5, 1.0, 2.0]):
            f = k * f0
            xl = 2 * m9.pi * f * l9_
            xc = 1 / (2 * m9.pi * f * c9_)
            zz = m9.hypot(r9_, xl - xc)
            current = 5 / zz
            values = dict(ur=current * r9_, ul=current * xl, uc=current * xc, i=current * 1000)
            observation(f"i{point+1}", values["i"], "mA")
            observation(f"ur{point+1}", values["ur"], "V")
            observation(f"ul{point+1}", values["ul"], "V")
            observation(f"uc{point+1}", values["uc"], "V")
            observation(f"ue{point+1}", 5, "V")
            if point == 0:
                first = values
            elif point == 1:
                resonant = values
        vector(1, [f0], ["Hz"])
        vector(3, [resonant["ul"] / 5, resonant["ul"] - resonant["uc"]], ["1", "V"])
        vector(5, [m9.hypot(first["ur"], first["ul"] - first["uc"]),
                   5 / (first["i"] / 1000), first["ur"] / 5,
                   first["ur"] * first["i"], (first["ul"] - first["uc"]) * first["i"],
                   5 * first["i"]], ["V", "Ohm", "1", "mW", "mvar", "mVA"])
        vector(6, [1, 1, 1], ["choice", "choice", "choice"])
        wiring = [["GEN_P", "K1"], ["K2", "A_P"], ["A_N", "R_A"],
                  ["R_B", "L_A"], ["L_B", "C_A"], ["C_B", "GEN_N"]]
        report["evidence"] = dict(wiring={"s1": dict(pairs=copy.deepcopy(wiring), meter="AC")})
    elif lab == "LD10":
        import math as m10
        l10_ = [10, 12, 15, 18, 22, 27, 33, 39][b] * 1e-3
        c10_ = [47, 56, 68, 82, 100, 120, 150, 180][a] * 1e-9
        qt10 = 2.0 + 0.5 * ((a + b) % 4)
        r10_ = round(100 * qt10 * m10.sqrt(l10_ / c10_)) / 100
        report["parameters"] = dict(E=5, R=r10_, L=l10_, C=c10_)
        f0 = 1 / (2 * m10.pi * m10.sqrt(l10_ * c10_))
        for point, k in enumerate([0.5, 1.0, 2.0]):
            f = k * f0
            xl = 2 * m10.pi * f * l10_
            xc = 1 / (2 * m10.pi * f * c10_)
            values = dict(ir=5 / r10_ * 1000, il=5 / xl * 1000, ic=5 / xc * 1000)
            admittance = complex(1 / r10_, 1 / xl - 1 / xc)
            values["i"] = 5 * abs(admittance) * 1000
            observation(f"u{point+1}", 5, "V")
            observation(f"ir{point+1}", values["ir"], "mA")
            observation(f"il{point+1}", values["il"], "mA")
            observation(f"ic{point+1}", values["ic"], "mA")
            observation(f"i{point+1}", values["i"], "mA")
            if point == 0:
                first = values
            elif point == 1:
                resonant = values
        vector(1, [f0], ["Hz"])
        vector(3, [resonant["il"] / resonant["i"], resonant["il"] - resonant["ic"]], ["1", "mA"])
        vector(5, [m10.hypot(first["ir"], first["il"] - first["ic"]),
                   first["i"] / 5, first["ir"] / first["i"],
                   5 * first["ir"], 5 * (first["il"] - first["ic"]),
                   5 * first["i"]], ["mA", "mS", "1", "mW", "mvar", "mVA"])
        vector(6, [1, 1, 1], ["choice", "choice", "choice"])
        wiring = [["GEN_P", "K1"], ["K2", "A_P"], ["A_N", "R_A"], ["R_A", "L_A"],
                  ["L_A", "C_A"], ["R_B", "GEN_N"], ["R_B", "L_B"], ["L_B", "C_B"]]
        report["evidence"] = dict(wiring={"s1": dict(pairs=copy.deepcopy(wiring), meter="AC")})
    elif lab == "LD11":
        import math as m11
        e11_ = [5, 6, 7, 8, 9, 10, 11, 12][b]
        r11_ = [10, 15, 22, 33, 47, 68, 82, 100][a]
        l11_ = [100, 150, 220, 330, 470, 680, 1000, 1500][(a + b) % 8] * 1e-3
        w11 = 2 * m11.pi * 50
        xl11 = w11 * l11_
        ck11 = round(xl11 / (w11 * (r11_ * r11_ + xl11 * xl11)) * 1e8) / 1e8
        report["parameters"] = dict(E=e11_, f=50, R=r11_, L=l11_, Ck=ck11)
        z11 = m11.hypot(r11_, xl11)
        i1 = e11_ / z11
        adm2 = complex(r11_ / (z11 * z11), xl11 / (z11 * z11) - w11 * ck11)
        i2 = e11_ * abs(adm2)
        p1 = e11_ * i1 * r11_ / z11
        q1 = e11_ * i1 * xl11 / z11
        s1 = e11_ * i1
        p2 = e11_ * i2 * (p1 / s1)  # P išlieka: aktyvioji dalis nepakinta
        p2 = p1
        s2 = e11_ * i2
        q2 = m11.sqrt(max(s2 * s2 - p2 * p2, 0.0))
        observation("u1", e11_, "V")
        observation("i1", i1 * 1000, "mA")
        observation("p1", p1 * 1000, "mW")
        observation("u2", e11_, "V")
        observation("i2", i2 * 1000, "mA")
        observation("p2", p2 * 1000, "mW")
        vector(1, [r11_ / z11], ["1"])
        vector(2, [s1 * 1000, q1 * 1000, p1 / s1], ["mVA", "mvar", "1"])
        vector(3, [ck11 * 1e6], ["uF"])
        vector(5, [s2 * 1000, q2 * 1000, p2 / s2, (s1 - s2) * 1000], ["mVA", "mvar", "1", "mVA"])
        vector(6, [1, 1, 1], ["choice", "choice", "choice"])
        base1 = [["GEN_P", "K1"], ["K2", "A_P"], ["A_N", "RL_A"], ["RL_B", "GEN_N"]]
        wirings = {"s1": base1, "s4": base1 + [["RL_A", "C_A"], ["C_B", "GEN_N"]]}
        report["evidence"] = dict(wiring={k: dict(pairs=copy.deepcopy(v), meter="AC") for k, v in wirings.items()})
    elif lab == "LD12":
        import math as m12
        ul12_ = [30, 40, 50, 60, 100, 110, 127, 220][b]
        r12_ = [10, 15, 22, 33, 47, 68, 82, 100][a]
        report["parameters"] = dict(Ul=ul12_, R=r12_)
        phase = ul12_ / m12.sqrt(3)
        i_star = phase / r12_ * 1000
        i_ph = ul12_ / r12_ * 1000
        i_line = i_ph * m12.sqrt(3)
        p_star = ul12_ * ul12_ / r12_
        p_delta = 3 * ul12_ * ul12_ / r12_
        observation("is", i_star, "mA")
        observation("id", i_ph, "mA")
        vector(1, [phase], ["V"])
        vector(2, [i_star], ["mA"])
        vector(3, [ul12_], ["V"])
        vector(4, [i_ph], ["mA"])
        vector(5, [i_line, p_delta * 1000, p_star * 1000], ["mA", "mW", "mW"])
        vector(6, [1, 1, 1], ["choice", "choice", "choice"])
        star = [["L1", "R1_A"], ["L2", "R2_A"], ["L3", "R3_A"], ["R1_B", "R2_B"], ["R2_B", "R3_B"], ["R3_B", "N"]]
        delta = [["L1", "R1_A"], ["R1_B", "L2"], ["L2", "R2_A"], ["R2_B", "L3"], ["L3", "R3_A"], ["R3_B", "L1"]]
        report["evidence"] = dict(wiring={"s1": dict(pairs=copy.deepcopy(star), meter="AC"),
                                          "s3": dict(pairs=copy.deepcopy(delta), meter="AC")})
    else:
        report["parameters"] = dict(E_RC=9,F_RC=frc,R8=r8,C2=4.7e-6,E_RL=9,F_RL=frl,R9=r9,L1=.5,
                                    E_RLC=5,R13=r13,L3=l,C4=c)
        for step, resistance, f, reactive, prefix in [(3,r8,frc,-1/(2*math.pi*frc*4.7e-6),"rc_"),
                                                       (6,r9,frl,2*math.pi*frl*.5,"rl_")]:
            z=math.hypot(resistance,reactive); current=9/z; ur=current*resistance; ux=current*abs(reactive)
            vector(step,[abs(reactive),z,current*1000,ur,ux,current**2*resistance*1000,
                         -math.degrees(math.atan2(reactive,resistance))], ["Ohm","Ohm","mA","V","V","mW","deg"])
            vector(step+1,[9,current*1000],["V","mA"])
            for key,value,unit in [("I",current,"A"),("UR",ur,"V"),("UC" if step==3 else "UL",ux,"V"),("UE",9,"V")]:
                observation(prefix+key,value,unit)
        f0=1/(2*math.pi*math.sqrt(l*c)); bw=r13/(2*math.pi*l); q=2*math.pi*f0*l/r13
        disc=math.sqrt(r13*r13+4*l/c); f1=(-r13+disc)/(4*math.pi*l); f2=(r13+disc)/(4*math.pi*l)
        fl=f0/math.sqrt(1-r13*r13*c/(2*l)); fc=f0*math.sqrt(1-r13*r13*c/(2*l))
        def values(f):
            if f==0:return dict(UR=0,UL=0,UC=5,ULC=5)
            xl=2*math.pi*f*l; xc=1/(2*math.pi*f*c); current=5/math.hypot(r13,xl-xc)
            return dict(UR=current*r13,UL=current*xl,UC=current*xc,ULC=current*abs(xl-xc))
        resonance=[dict(f=f,u=values(f)["UR"]) for f in [f0-bw/2,f0,f0+bw/2]]
        peaks=[dict(target=t,f=f,u=values(f)[t]) for t,center in [("UL",fl),("UC",fc),("ULC",f0)] for f in [center-bw/2,center,center+bw/2]]
        vector(9,[f0,f0,1000/f0,5],["Hz","Hz","ms","V"])
        vector(10,[values(fl)["UL"],values(fc)["UC"],values(f0)["ULC"],fl,fc,f0],["V","V","V","Hz","Hz","Hz"])
        vector(11,[5/math.sqrt(2),f1,f2,bw,q],["V","Hz","Hz","Hz","1"])
        for key,value,unit in [("f1_meas",f1,"Hz"),("f2_meas",f2,"Hz"),("f1_u",5/math.sqrt(2),"V"),("f2_u",5/math.sqrt(2),"V")]:
            observation(key,value,unit)
        wiring={}
        for phase,first,second in [("RC","R8","C2"),("RL","R9","L1"),("RLC","C4","L3")]:
            wires=[["GEN_H","AM_H"],["AM_L",first+"_1"],[first+"_2",second+"_1"],[("R13" if phase=="RLC" else second)+"_2","GEN_L"]]
            if phase=="RLC":wires.append(["L3_2","R13_1"])
            wiring[phase]=wires
        report["evidence"]=dict(wiring=wiring,resonance=resonance,peaks=peaks,
            sweep=[dict(f=f,u=values(f)["UR"]) for f in range(0,10001,1000)],journal=[])
    return report

def write(path, report):
    encoded=json.dumps(report,ensure_ascii=False,allow_nan=False).replace("<","\\u003c")
    path.write_text('<!doctype html><meta charset="utf-8">'+START+encoded+'</script>',encoding="utf-8")

def run(exe, source, destination):
    start=time.monotonic()
    p=subprocess.run([str(exe),str(source),str(destination)],capture_output=True,text=True,timeout=90)
    assert p.returncode==0,p.stderr
    return json.loads((destination/"vertinimai.json").read_text(encoding="utf-8")),time.monotonic()-start

def main(exe):
    with tempfile.TemporaryDirectory(prefix="LD testai Žąsė ") as temp:
        root=Path(temp);source=root/"Studentų darbai";source.mkdir(); expected={}
        for i in range(650):
            lab="LD1" if i%2==0 else "LD2";r=fixture(lab,(i//2)%64+1,i);maximum=22 if lab=="LD1" else 50
            points=maximum
            if i%13==0:r["answers"][0]["raw"]="999999";points-=1
            if i%17==0:r["answers"][1]["raw"]="";points-=1
            # Untrusted suggested grades / completion flags must have no effect.
            r["suggested_grade"]=10;r["completed"]=[True]*12
            filename=f"{i:04d}.html";write(source/filename,r);expected[filename]=(points,maximum)
        data,seconds=run(exe,source,root/"Įvertinimai")
        assert data["complete"] and len(data["results"])==650
        for v in data["results"]:
            assert v["status"]=="graded",v
            assert (v["points"],v["max_points"])==expected[v["file"]],v
        replay,_=run(exe,source,root/"Pakartota")
        assert data==replay,"Nondeterministic replay"
        assert seconds<60,seconds
        adversarial=root/"Blogi failai";adversarial.mkdir();base=fixture("LD2",17,"good")
        mutations={
            "schema":lambda r:r.update(schema_version=99),
            "bool_variant":lambda r:r.update(variant=True),
            "range":lambda r:r.update(variant=65),
            "bank":lambda r:r.update(bank_id="changed"),
            "unit":lambda r:r["answers"][0].update(unit="A"),
            "config":lambda r:r["parameters"].update(R8=42),
            "duplicate_item":lambda r:r["answers"].append(r["answers"][0]),
            "unknown_item":lambda r:r["answers"].append(dict(id="unexpected",raw="1",unit="A")),
            "bad_points":lambda r:r["evidence"]["resonance"][0].update(f="exec()"),
            "identity_newline":lambda r:r["student"].update(name="Vardas\nSugadinta eilutė"),
        }
        for name,mutate in mutations.items():
            r=copy.deepcopy(base);mutate(r);write(adversarial/(name+".html"),r)
        (adversarial/"duplicate_key.html").write_text(START+'{"schema_version":1,"schema_version":1}</script>')
        (adversarial/"deep.html").write_text(START+'['*40+'0'+']'*40+'</script>')
        (adversarial/"large.html").write_text('x'*(2*1024*1024+1))
        (adversarial/"truncated.html").write_text(START+'{"schema_version":1')
        (adversarial/"senas.pdf").write_bytes(b'%PDF-1.4')
        r=copy.deepcopy(base);r["answers"][0]["raw"]="exec('secret')";r["answers"][1]["raw"]="1e999";r["submission_id"]="invalid-numbers"
        write(adversarial/"invalid_numbers.html",r)
        write(adversarial/"good.html",base);write(adversarial/"good_copy.html",base)
        data,_=run(exe,adversarial,root/"Blogų rezultatai")
        statuses=[v["status"] for v in data["results"]]
        assert statuses.count("review")==15,statuses
        assert statuses.count("graded")==2 and statuses.count("duplicate")==1,statuses
        inv=next(v for v in data["results"] if v["file"]=="invalid_numbers.html")
        assert inv["points"]==48
        # A conflicting ID invalidates both candidates, regardless of sorting.
        conflicts=root/"Konfliktai";conflicts.mkdir();write(conflicts/"a.html",base)
        changed=copy.deepcopy(base);changed["answers"][0]["raw"]="0";write(conflicts/"b.html",changed)
        data,_=run(exe,conflicts,root/"Konfliktų rezultatai")
        assert all(v["status"]=="conflict" and v["grade_10"] is None for v in data["results"])
        # Better valid attempt is selected; the weaker attempt remains visible.
        attempts=root/"Bandymai";attempts.mkdir();write(attempts/"a.html",base)
        changed["submission_id"]="new-attempt";write(attempts/"b.html",changed)
        data,_=run(exe,attempts,root/"Bandymų rezultatai")
        assert [v["selected_for_summary"] for v in data["results"]]==[True,False]
        # Runtime emits ordinary UTF-8 with a valid BOM for spreadsheet import.
        with (root/"Įvertinimai"/"suvestine.csv").open(encoding="utf-8-sig",newline="") as f:
            rows=list(csv.reader(f,delimiter=";"));assert rows[0][0]=="Failas" and len(rows)==651
        # LD3 (Omo dėsnis): savarankiškas scenarijus per tą patį ldcheck.
        ld3=root/"LD3 ataskaitos";ld3.mkdir()
        for n,name in [(1,"v1"),(17,"v17"),(64,"v64")]:
            write(ld3/(name+".html"),fixture("LD3",n,name))
        wrong=fixture("LD3",9,"w9");wrong["answers"][1]["raw"]="999";write(ld3/"blogas_r1.html",wrong)
        missing=fixture("LD3",25,"m25")
        missing["observations"]=[o for o in missing["observations"] if o["id"]!="i2"]
        write(ld3/"truksta_i2.html",missing)
        (ld3/"siunta.pdf").write_bytes(b'%PDF-1.4')
        data,_=run(exe,ld3,root/"LD3 rezultatai")
        assert data["complete"] and len(data["results"])==6,data
        by={v["file"]:v for v in data["results"]}
        for name in ("v1.html","v17.html","v64.html"):
            assert by[name]["status"]=="graded",by[name]
            assert (by[name]["points"],by[name]["max_points"])==(15,15),by[name]
        assert by["blogas_r1.html"]["status"]=="graded"
        assert (by["blogas_r1.html"]["points"],by["blogas_r1.html"]["max_points"])==(14,15)
        assert next(i for i in by["blogas_r1.html"]["items"] if i["id"]=="s4.q1")["status"]=="incorrect"
        assert (by["truksta_i2.html"]["points"],by["truksta_i2.html"]["max_points"])==(12,15)
        statuses={i["id"]:i["status"] for i in by["truksta_i2.html"]["items"]}
        assert statuses["i2"]=="missing" and statuses["s4.q2"]=="missing_evidence"
        assert statuses["s4.q4"]=="missing_evidence" and statuses["s4.q1"]=="correct"
        assert by["siunta.pdf"]["status"]=="review"
        with (root/"LD3 rezultatai"/"suvestine.csv").open(encoding="utf-8-sig",newline="") as f:
            assert len(list(csv.reader(f,delimiter=";")))==7
        # LD4: all variants, genuine stage evidence, nominal prediction and limits.
        ld4=root/"LD4 ataskaitos";ld4.mkdir()
        for n in range(1,65):write(ld4/f"v{n:02d}.html",fixture("LD4",n,f"v{n}"))
        cases={}
        for name in ["empty", "missing_s6", "wrong_s1", "boundary", "outside", "actual_as_theory"]:
            r=fixture("LD4",1,name)
            if name=="empty":
                r["answers"]=[];r["observations"]=[]
                for stage in ["s1","s6"]:r["evidence"]["wiring"][stage]["pairs"]=[]
                cases[name]=0
            elif name=="missing_s6":r["evidence"]["wiring"]["s6"]["pairs"]=[];cases[name]=26
            elif name=="wrong_s1":r["evidence"]["wiring"]["s1"]=r["evidence"]["wiring"]["s6"];cases[name]=26
            else:
                r["answers"][0]["raw"]={"boundary":"30.3","outside":"30.45","actual_as_theory":"31.25"}[name]
                cases[name]=27 if name=="boundary" else 26
            write(ld4/(name+".html"),r)
        data,_=run(exe,ld4,root/"LD4 rezultatai")
        for r in data["results"]:
            assert r["status"]=="graded",r
            assert r["points"]==cases.get(Path(r["file"]).stem,27),r
            assert r["max_points"]==27,r
        print(json.dumps(dict(status="PASS",full_reports=650,seconds=round(seconds,3),adversarial_files=17,
                              deterministic_replay=True,conflicting_ids=True,multiple_attempts=True,utf8_paths=True,
                              ld3_batch=True)))

if __name__=="__main__":main(Path(sys.argv[1]).resolve())
