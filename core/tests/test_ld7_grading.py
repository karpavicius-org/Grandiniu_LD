import copy
import ctypes
import json
import math
from pathlib import Path
import sys
import tempfile
from test_grading import fixture, write, run


def match_reference(emf, internal, load):
    """Independent Kirchhoff prediction: source E with r and load R."""
    current = emf / (load + internal)
    return [current * load, current * 1000]


def variant_values(number):
    row, column = divmod(number - 1, 8)
    emf = [3, 4, 5, 6, 7, 8, 10, 12][column]
    internal = [22, 27, 33, 39, 47, 56, 68, 82][row]
    load = [round(k * internal * 10) / 10 for k in [0.33, 0.56, 1.0, 1.8, 3.0]]
    return emf, internal, load


def fixture_v2(number, identity):
    """LD7-2 analytical fixture; LD7-1 fixture remains completely untouched."""
    report = fixture('LD7', number, identity)
    old = {a['id']: a for a in report['answers']}
    emf, internal, loads = variant_values(number)
    u1, _ = match_reference(emf, internal, loads[0])
    translated = [
        ('s3.q1', float(old['s3.q1']['raw']), 'Ohm'),
        ('s3.q2', emf - u1, 'V'),
        ('s4.q1', float(old['s4.q2']['raw']), 'mW'),  # P3 from U3 and I3
        ('s4.q2', float(old['s4.q4']['raw']), 'mW'),  # Pmax from E and r
        ('s4.q3', 50, '1'),
        ('s6.q1', 1, 'choice'),
        ('s6.q2', 1, 'choice'),
        ('s6.q3', 1, 'choice'),
    ]
    report['answers'] = [dict(id=key, raw=format(value, '.17g'), unit=unit)
                         for key, value, unit in translated]
    report.update(lab_revision='2', rubric_version='LD7-2')
    assert len(report['answers']) == 8
    return report


def main(executable, library):
    core = ctypes.CDLL(str(library)); scalar = ctypes.c_int
    vector = ctypes.c_double * 5; output_type = ctypes.c_double * 4
    core.ld_sources.argtypes = [ctypes.POINTER(scalar), ctypes.POINTER(ctypes.c_double),
                               ctypes.POINTER(ctypes.c_double), ctypes.POINTER(scalar)]
    mna_cases = 0
    for number in range(1, 65):
        emf, internal, load = variant_values(number)
        powers = [emf ** 2 * rr / (rr + internal) ** 2 for rr in load]
        assert max(powers) == powers[2] and load[2] == internal
        assert load[0] < internal < load[4]
        for rr in load + [1e6, 1e-6]:
            output = output_type(); status = scalar(99)
            core.ld_sources(ctypes.byref(scalar(1)), vector(emf, emf, rr, internal, internal),
                            output, ctypes.byref(status))
            assert status.value == 0
            assert all(math.isclose(actual, expected, rel_tol=1e-10, abs_tol=1e-10)
                       for actual, expected in zip(output[:2], match_reference(emf, internal, rr)))
            voltage, load_current = output[0], output[1] / 1000
            source_current = output[2] / 1000
            assert math.isclose(source_current, load_current, abs_tol=1e-10)
            assert math.isclose(emf * source_current,
                                voltage * load_current + source_current ** 2 * internal,
                                abs_tol=1e-9)
            mna_cases += 1
    for inputs in [(0, 3, 100, 22, 22), (1, math.nan, 100, 22, 22),
                   (1, 3, 0, 22, 22), (1, 3, 100, 0, 22)]:
        status = scalar(99); output = output_type()
        core.ld_sources(ctypes.byref(scalar(1)), vector(*inputs), output, ctypes.byref(status))
        assert status.value != 0

    with tempfile.TemporaryDirectory(prefix='LD7 Žąsė ') as temporary:
        root = Path(temporary); folder = root / 'Darbai'; folder.mkdir(); expected = {}
        for number in range(1, 65):
            for label, report, maximum in [('historical', fixture('LD7', number, f'old-{number}'), 27),
                                           ('current', fixture_v2(number, f'new-{number}'), 18)]:
                if number % 2:
                    for stage in report['evidence']['wiring'].values():
                        stage['pairs'] = [pair[::-1] for pair in stage['pairs'][::-1]]
                filename = f'{label}-{number:02d}.html'
                write(folder / filename, report); expected[filename] = (maximum, maximum)

        for stage in ['s1', 's5te', 's5tj']:
            for damage in ['missing', 'duplicate', 'extra_endpoint']:
                report = fixture_v2(1, f'{stage}-{damage}')
                pairs = report['evidence']['wiring'][stage]['pairs']
                if damage == 'missing': pairs.pop()
                elif damage == 'duplicate': pairs[-1] = copy.deepcopy(pairs[0])
                else: pairs[0].append('R_B')
                name = f'new-{stage}-{damage}.html'
                write(folder / name, report); expected[name] = (17, 18)
        for which in ['u3', 'i3']:
            report = fixture_v2(17, f'missing-{which}')
            report['observations'] = [x for x in report['observations'] if x['id'] != which]
            name = f'new-missing-{which}.html'
            write(folder/name, report); expected[name] = (17, 18)
        report = fixture_v2(17, 'both-corrupt')
        for obs in report['observations']:
            if obs['id'] in ('u3', 'i3'): obs['value'] = 999999
        write(folder/'new-both-corrupt.html', report)
        expected['new-both-corrupt.html'] = (17, 18)  # same real measurement, not two penalties

        for name, factor in [('inside', 1.019), ('outside', 1.021)]:
            report = fixture_v2(17, name)
            answer = next(x for x in report['answers'] if x['id'] == 's4.q2')
            answer['raw'] = format(float(answer['raw']) * factor, '.17g')
            filename = f'new-boundary-{name}.html'
            write(folder/filename, report)
            expected[filename] = (18 if name == 'inside' else 17, 18)

        report = fixture_v2(23, 'te-off')
        next(x for x in report['observations'] if x['id'] == 'te_u')['value'] += 0.006
        write(folder/'new-te-off.html', report); expected['new-te-off.html'] = (17, 18)
        report = fixture_v2(23, 'tj-off')
        next(x for x in report['observations'] if x['id'] == 'tj_i')['value'] += 0.03 * (report['parameters']['E']/report['parameters']['r']*1000)
        write(folder/'new-tj-off.html', report); expected['new-tj-off.html'] = (17, 18)

        # A correctly rounded inferred r must be accepted consistently in
        # dependent Ur and Pmax calculations; an actually wrong r must not.
        for label, factor, score in [('rounded', 1.025, 18), ('wrong', 1.05, 15)]:
            report = fixture_v2(17, label)
            p = report['parameters']
            r_used = p['r'] * factor
            readings = {x['id']: x['value'] for x in report['observations']}
            updated = {
                's3.q1': r_used,
                's3.q2': readings['i1'] * r_used / 1000,
                's4.q2': 1000 * p['E'] * p['E'] / (4 * r_used),
            }
            for answer in report['answers']:
                if answer['id'] in updated:
                    answer['raw'] = format(updated[answer['id']], '.17g')
            name = f'new-{label}-r.html'
            write(folder/name, report); expected[name] = (score, 18)

        report = fixture_v2(64, 'empty')
        report['answers'] = []; report['observations'] = []; report['evidence']['wiring'] = {}
        write(folder/'new-empty.html', report); expected['new-empty.html'] = (0, 18)
        old = fixture('LD7', 17, 'old-off')
        next(x for x in old['answers'] if x['id'] == 's5.q1')['raw'] = 'invalid'
        write(folder/'old-wrong.html', old); expected['old-wrong.html'] = (26, 27)

        results, seconds = run(executable, folder, root/'Vertinimas')
        assert len(results['results']) == len(expected), (len(results['results']), len(expected))
        for result in results['results']:
            assert result['status'] == 'graded', result
            assert (result['points'], result['max_points']) == expected[result['file']], result
        print(json.dumps(dict(status='PASS', variants=64, mna_cases=mna_cases,
                              graded_reports=len(expected), rubric_v2=18,
                              historical_v1=27, grouped_measurements=True,
                              no_copied_meter_points=True, power_balance=True,
                              seconds=round(seconds, 3))))


if __name__ == '__main__':
    main(Path(sys.argv[1]).resolve(), Path(sys.argv[2]).resolve())
