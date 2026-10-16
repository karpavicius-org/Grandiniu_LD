import copy
import json
import math
from pathlib import Path
import sys
import tempfile
from test_grading import fixture, write, run


def variant_values(number):
    a, b = divmod(number - 1, 8)
    e = [5, 6, 7, 8, 9, 10, 11, 12][b]
    r = [10, 15, 22, 33, 47, 68, 82, 100][a]
    l = [100, 150, 220, 330, 470, 680, 1000, 1500][(a + b) % 8] * 1e-3
    w = 2 * math.pi * 50
    xl = w * l
    ck = round(xl / (w * (r * r + xl * xl)) * 1e8) / 1e8
    return e, r, l, ck


def main(executable):
    for number in range(1, 65):
        e, r, l, ck = variant_values(number)
        w = 2 * math.pi * 50
        xl = w * l
        z = math.hypot(r, xl)
        cos0 = r / z
        # Kompensacija visada pagerina cos φ ir sumažina pilnutinę galią.
        assert 0.02 <= cos0 <= 0.98, (number, cos0)
        i1 = e / z
        # Nuoseklaus RIŠLĖS laidis: G = R/Z², B = −XL/Z² (ne 1/XL!).
        admittance = complex(r / (z * z), xl / (z * z) - w * ck)
        i2 = e * abs(admittance)
        assert i2 < i1 + 1e-12, (number, i1, i2)
        p = e * i1 * cos0
        assert 1e-4 <= ck * 1e6 <= 500.0, (number, ck * 1e6)
    with tempfile.TemporaryDirectory(prefix='LD11 Žąsė ') as temporary:
        root = Path(temporary); folder = root / 'Darbai'; folder.mkdir(); expected = {}
        for number in range(1, 65):
            report = fixture('LD11', number, f'v{number}')
            if number % 2:
                for stage in report['evidence']['wiring'].values():
                    stage['pairs'] = [pair[::-1] for pair in stage['pairs'][::-1]]
            filename = f'v{number:02d}.html'; write(folder/filename, report); expected[filename] = 20
        for number in range(1, 65):
            e, r, l, ck = variant_values(number)
            w = 2 * math.pi * 50
            load = 1 / complex(r, w * l)
            corrected = load + complex(0, w * ck)
            # Match the public journal's six decimal places, not hidden precision.
            i1 = float(f"{e * abs(load) * 1000:.6f}")
            i2 = float(f"{e * abs(corrected) * 1000:.6f}")
            p = float(f"{e * e * load.real * 1000:.6f}")
            s1, s2 = e * i1, e * i2
            # Q2 uses the known physical components: the rounded power triangle
            # is ill-conditioned near perfect compensation (all 64 old displays failed).
            displayed_ck = float(f"{ck * 1e6:g}") / 1e6
            residual = (load + complex(0, w * displayed_ck)).imag
            values = {'s1.q1': r / abs(complex(r, w * l)),
                      's2.q1': s1, 's2.q2': math.sqrt((s1-p)*(s1+p)), 's2.q3': p/s1,
                      's3.q1': (w*l)/(w*(r*r+(w*l)**2))*1e6,
                      's5.q1': s2, 's5.q2': abs(e*e*residual)*1000,
                      's5.q3': p/s2, 's5.q4': s1-s2}
            report = fixture('LD11', number, f'display-{number}')
            for item in report['answers']:
                if item['id'] in values:
                    item['raw'] = format(values[item['id']], '.12g')
            filename = f'display-{number:02d}.html'
            write(folder/filename, report); expected[filename] = 20
        for stage in ['s1', 's4']:
            for damage in ['missing', 'duplicate', 'extra_endpoint']:
                name = f'{stage}-{damage}.html'; report = fixture('LD11', 1, name)
                pairs = report['evidence']['wiring'][stage]['pairs']
                if damage == 'missing': pairs.pop()
                elif damage == 'duplicate': pairs[-1] = copy.deepcopy(pairs[0])
                else: pairs[0].append('GEN_N')
                write(folder/name, report); expected[name] = 19
        report = fixture('LD11', 64, 'empty')
        report['answers'] = []; report['observations'] = []; report['evidence']['wiring'] = {}
        write(folder/'empty.html', report); expected['empty.html'] = 0
        for key, tolerance in [('s3.q1', .03), ('s1.q1', .01)]:
            report = fixture('LD11', 17, key)
            answer = next(item for item in report['answers'] if item['id'] == key)
            base = float(answer['raw'])
            for name, factor in [('in', 1 + tolerance * .999), ('out', 1 + tolerance * 1.001)]:
                report = fixture('LD11', 17, f'{key}-{name}')
                answer = next(item for item in report['answers'] if item['id'] == key)
                answer['raw'] = format(base * factor, '.17g')
                filename = f'{key}-{name}.html'; write(folder/filename, report)
                expected[filename] = 20 if name == 'in' else 19
        results, seconds = run(executable, folder, root/'Vertinimas')
        assert len(results['results']) == len(expected)
        for result in results['results']:
            assert result['status'] == 'graded' and result['points'] == expected[result['file']], result
        print(json.dumps(dict(status='PASS', variants=64, graded_reports=len(expected),
                              compensation_improves=True, active_power_kept=True, displayed_reading_variants=64, seconds=round(seconds, 3))))


if __name__ == '__main__': main(Path(sys.argv[1]).resolve())
