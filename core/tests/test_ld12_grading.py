import cmath
import ctypes as c
import copy
import json
import math
from pathlib import Path
import sys
import tempfile
from test_grading import fixture, write, run


def variant_values(number):
    a, b = divmod(number - 1, 8)
    ul = [30, 40, 50, 60, 100, 110, 127, 220][b]
    r = [10, 15, 22, 33, 47, 68, 82, 100][a]
    return ul, r


def check_engine(lib, ul, r):
    sources = [ul/math.sqrt(3)*cmath.exp(1j*a) for a in (0, -2*math.pi/3, 2*math.pi/3)]
    phase_delta = [(sources[k]-sources[(k+1)%3])/r for k in range(3)]
    line_delta = [phase_delta[k]-phase_delta[(k-1)%3] for k in range(3)]
    power_y = sum((v*(v/r).conjugate()).real for v in sources)
    power_d = sum(((sources[k]-sources[(k+1)%3])*phase_delta[k].conjugate()).real for k in range(3))
    expected = [abs(sources[0]), abs(sources[0]/r)*1000, ul,
                abs(phase_delta[0])*1000, abs(line_delta[0])*1000, power_y, power_d, ul]
    params=(c.c_double*5)(ul,50,r,1,1);values=(c.c_double*10)();status=c.c_int(9)
    lib.ld_ac(c.byref(c.c_int(6)),params,values,c.byref(status));assert status.value==0
    for got,want in zip(values,expected):assert math.isclose(got,want,rel_tol=1e-10,abs_tol=1e-8),(got,want)
    for delta in (False,True):
        rows=[[4,k+1,0,v.real,v.imag] for k,v in enumerate(sources)]
        rows += [[1,1,2,r,0],[1,2,3,r,0],[1,3,1,r,0]] if delta else [[1,k+1,0,r,0] for k in range(3)]
        m=len(rows);n=3
        table=(c.c_double*(m*5))(*(rows[k][j] for j in range(5) for k in range(m)))
        voltage=(c.c_double*8)();current=(c.c_double*(m*2))();status=c.c_int(9)
        lib.ld_mna(table,c.byref(c.c_int(m)),c.byref(c.c_int(n)),c.byref(c.c_double(50)),voltage,current,c.byref(status))
        assert status.value==0
        currents=[complex(current[k],current[m+k]) for k in range(m)]
        load_expected=phase_delta if delta else [v/r for v in sources]
        line_expected=line_delta if delta else load_expected
        for got,want in zip(currents[3:],load_expected):assert abs(got-want)<1e-9,(got,want)
        for got,want in zip(currents[:3],line_expected):assert abs(-got-want)<1e-9,(got,want)
        assert abs(sum(currents[:3]))<1e-9
        power=-sum((sources[k]*currents[k].conjugate()).real for k in range(3))
        assert math.isclose(power,power_d if delta else power_y,rel_tol=1e-10)


def main(executable, core=None):
    lib=None
    if core:
        lib=c.CDLL(str(core));D=c.POINTER(c.c_double);I=c.POINTER(c.c_int)
        lib.ld_ac.argtypes=[I,D,D,I];lib.ld_mna.argtypes=[D,I,I,D,D,D,I]

    for number in range(1, 65):
        ul, r = variant_values(number)
        if lib:check_engine(lib,ul,r)
        phase = ul / math.sqrt(3)
        i_star = phase / r
        i_ph = ul / r
        # Trikampis: linijinė = √3·fazinė; trikampio galia = 3 × žvaigždės.
        p_star = 3 * phase * i_star
        p_delta = math.sqrt(3) * ul * (i_ph * math.sqrt(3))
        assert math.isclose(p_delta, 3 * ul * ul / r, rel_tol=1e-12)
        assert math.isclose(p_star, ul * ul / r, rel_tol=1e-12)
        assert math.isclose(p_delta, 3 * p_star, rel_tol=1e-12)
    with tempfile.TemporaryDirectory(prefix='LD12 Žąsė ') as temporary:
        root = Path(temporary); folder = root / 'Darbai'; folder.mkdir(); expected = {}
        for number in range(1, 65):
            report = fixture('LD12', number, f'v{number}')
            if number % 2:
                for stage in report['evidence']['wiring'].values():
                    stage['pairs'] = [pair[::-1] for pair in stage['pairs'][::-1]]
            filename = f'v{number:02d}.html'; write(folder/filename, report); expected[filename] = 14
        # Grade answers calculated at the precision actually shown in the public journal.
        for number in range(1,65):
            ul,r=variant_values(number)
            uy=float(f"{ul/math.sqrt(3):.4f}");iy=float(f"{ul/math.sqrt(3)/r*1000:.3f}")
            ud=float(f"{ul:.4f}");idelta=float(f"{ul/r*1000:.3f}")
            line=idelta*math.sqrt(3)
            values={'s1.q1':ul/math.sqrt(3),'s2.q1':uy/r*1000,'s3.q1':ul,'s4.q1':ud/r*1000,
                    's5.q1':line,'s5.q2':math.sqrt(3)*ul*line,'s5.q3':3*uy*iy}
            report=fixture('LD12',number,f'display-{number}')
            for answer in report['answers']:
                if answer['id'] in values:answer['raw']=format(values[answer['id']],'.12g')
            filename=f'display-{number:02d}.html';write(folder/filename,report);expected[filename]=14
        for stage in ['s1', 's3']:
            for damage in ['missing', 'duplicate', 'extra_endpoint']:
                name = f'{stage}-{damage}.html'; report = fixture('LD12', 1, name)
                pairs = report['evidence']['wiring'][stage]['pairs']
                if damage == 'missing': pairs.pop()
                elif damage == 'duplicate': pairs[-1] = copy.deepcopy(pairs[0])
                else: pairs[0].append('N')
                write(folder/name, report); expected[name] = 13
        report = fixture('LD12', 64, 'empty')
        report['answers'] = []; report['observations'] = []; report['evidence']['wiring'] = {}
        write(folder/'empty.html', report); expected['empty.html'] = 0
        for key, tolerance in [('s1.q1', .01), ('s4.q1', .02)]:
            report = fixture('LD12', 17, key)
            answer = next(item for item in report['answers'] if item['id'] == key)
            base = float(answer['raw'])
            for name, factor in [('in', 1 + tolerance * .999), ('out', 1 + tolerance * 1.001)]:
                report = fixture('LD12', 17, f'{key}-{name}')
                answer = next(item for item in report['answers'] if item['id'] == key)
                answer['raw'] = format(base * factor, '.17g')
                filename = f'{key}-{name}.html'; write(folder/filename, report)
                expected[filename] = 14 if name == 'in' else 13
        results, seconds = run(executable, folder, root/'Vertinimas')
        assert len(results['results']) == len(expected)
        for result in results['results']:
            assert result['status'] == 'graded' and result['points'] == expected[result['file']], result
        print(json.dumps(dict(status='PASS', variants=64, graded_reports=len(expected),
                              sqrt3_relations=True, power_formulas_agree=True, displayed_reading_variants=64, engine_variants=64 if lib else 0, seconds=round(seconds, 3))))


if __name__ == '__main__': main(Path(sys.argv[1]).resolve(),Path(sys.argv[2]).resolve() if len(sys.argv)>2 else None)
