import copy
import ctypes
import json
import math
from pathlib import Path
import sys
import tempfile
from test_grading import fixture, write, run


def source_reference(parameters, mode):
    first, second, load, internal_first, internal_second = parameters
    if mode == 1:
        current = first / (load + internal_first)
    elif mode in (2, 3):
        current = (first + (second if mode == 2 else -second)) / (load + internal_first + internal_second)
    else:
        voltage = (first / internal_first + second / internal_second) / (1 / load + 1 / internal_first + 1 / internal_second)
        current = voltage / load
    voltage = current * load
    first_current = current
    second_current = 0 if mode == 1 else current * (1 if mode == 2 else -1)
    if mode == 4:
        first_current = (first - voltage) / internal_first
        second_current = (second - voltage) / internal_second
    return [voltage, current * 1000, first_current * 1000, second_current * 1000]


def fixture_v2(number, identity):
    report = fixture('LD6', number, identity)
    nominal = report['parameters']['Rnom']
    parameters = dict(E1=9, E2=report['parameters']['E2'], Rnom=nominal,
                      R=round(nominal * (1 + (number % 11 - 5) / 100) * 10) / 10, r1=10, r2=10)
    report.update(parameters=parameters, bank_id='LD6-64-B-2026', lab_revision='2', rubric_version='LD6-2')
    values = [source_reference([parameters[key] for key in ['E1', 'E2', 'R', 'r1', 'r2']], mode) for mode in range(1, 5)]
    answers = [('s2.q1', values[0][1], 'mA')]
    answers += [(f's4.q{index+1}', value, ['V', 'mA'][index % 2]) for index, value in enumerate(values[1][:2] + values[2][:2])]
    answers += [(f's5.q{index+1}', value, 'V' if index == 0 else 'mA') for index, value in enumerate(values[3])]
    answers += [('s6.q1', 1, 'choice'), ('s6.q2', 2, 'choice')]
    report['answers'] = [dict(id=key, raw=format(value, '.17g'), unit=unit) for key, value, unit in answers]
    report['observations'] = [dict(id=f'{prefix}{mode}', value=values[mode-1][index], unit=unit)
                              for mode in range(1, 5) for index, prefix, unit in [(0, 'u', 'V'), (1, 'i', 'mA')]]
    report['observations'] += [dict(id=f'parallel_i{index-1}', value=values[3][index], unit='mA') for index in [2, 3]]
    base = [['E1_P', 'K1'], ['K2', 'A_P'], ['A_N', 'R_A'], ['V_P', 'R_A'], ['V_N', 'R_B']]
    connections = [base + [['R_B', 'E1_N']], base + [['R_B', 'E2_N'], ['E2_P', 'E1_N']],
                   base + [['R_B', 'E2_P'], ['E2_N', 'E1_N']],
                   base + [['R_B', 'E1_N'], ['E1_P', 'E2_P'], ['E1_N', 'E2_N']]]
    report['evidence'] = dict(wiring={f's{stage}': dict(pairs=copy.deepcopy(connections[index]), meter='DC')
                                    for index, stage in enumerate([1, 3, 4, 5])})
    return report



def fixture_v3(number, identity):
    report = fixture_v2(number, identity)
    p = report['parameters']
    report.update(lab_revision='3', rubric_version='LD6-3')
    values = [source_reference([p[key] for key in ['E1', 'E2', 'R', 'r1', 'r2']], mode) for mode in range(1, 5)]
    eeq = (p['E1']/p['r1'] + p['E2']/p['r2']) / (1/p['r1'] + 1/p['r2'])
    req = 1 / (1/p['r1'] + 1/p['r2'])
    answers = [
        ('s2.q1', values[0][1], 'mA'),
        ('s4.q1', p['E1'] + p['E2'], 'V'),
        ('s4.q2', p['E1'] - p['E2'], 'V'),
        ('s5.q1', eeq, 'V'),
        ('s5.q2', req, 'Ohm'),
        ('s6.q1', 1, 'choice'),
        ('s6.q2', 2, 'choice'),
    ]
    report['answers'] = [dict(id=key, raw=format(value, '.17g'), unit=unit) for key, value, unit in answers]
    return report

def main(executable, library):
    core = ctypes.CDLL(str(library)); scalar = ctypes.c_int
    vector = ctypes.c_double * 5; output_type = ctypes.c_double * 4
    core.ld_sources.argtypes = [ctypes.POINTER(scalar), ctypes.POINTER(ctypes.c_double),
                               ctypes.POINTER(ctypes.c_double), ctypes.POINTER(scalar)]
    for number in range(1, 65):
        parameters = fixture_v2(number, str(number))['parameters']
        inputs = [parameters[key] for key in ['E1', 'E2', 'R', 'r1', 'r2']]
        for mode in range(1, 5):
            output = output_type(); status = scalar(99)
            core.ld_sources(ctypes.byref(scalar(mode)), vector(*inputs), output, ctypes.byref(status))
            assert status.value == 0
            assert all(math.isclose(actual, expected, rel_tol=1e-10, abs_tol=1e-10)
                       for actual, expected in zip(output, source_reference(inputs, mode)))
            voltage, load_current, first_current, second_current = output
            load_current /= 1000; first_current /= 1000; second_current /= 1000
            if mode == 4:
                assert math.isclose(first_current + second_current, load_current, abs_tol=1e-10)
            assert math.isclose(inputs[0]*first_current + inputs[1]*second_current,
                                voltage*load_current + first_current**2*inputs[3] + second_current**2*inputs[4], abs_tol=1e-10)
    for mode in [3, 4]:
        inputs = [9, 9, 100, 10, 10]; output = output_type(); status = scalar(99)
        core.ld_sources(ctypes.byref(scalar(mode)), vector(*inputs), output, ctypes.byref(status))
        assert status.value == 0
        assert all(math.isclose(actual, expected, abs_tol=1e-10) for actual, expected in zip(output, source_reference(inputs, mode)))
    for mode, inputs in [(0, [9, 3, 100, 10, 10]), (4, [9, 3, 100, 0, 10]), (4, [9, math.nan, 100, 10, 10])]:
        status = scalar(99); output = output_type()
        core.ld_sources(ctypes.byref(scalar(mode)), vector(*inputs), output, ctypes.byref(status))
        assert status.value != 0
    with tempfile.TemporaryDirectory(prefix='LD6 Žąsė ') as temporary:
        root = Path(temporary); folder = root / 'Darbai'; folder.mkdir(); expected = {}
        for number in range(1, 65):
            old = fixture_v2(number, f'v2-{number}')
            current = fixture_v3(number, f'v3-{number}')
            for report in [old, current]:
                for stage in report['evidence']['wiring'].values():
                    if number % 2: stage['pairs'] = [pair[::-1] for pair in stage['pairs'][::-1]]
            name2 = f'v2-{number:02d}.html'; write(folder/name2, old); expected[name2] = (25, 25)
            name3 = f'v3-{number:02d}.html'; write(folder/name3, current); expected[name3] = (15, 15)

        for stage in [1, 3, 4, 5]:
            name = f'v3-s{stage}-missing.html'; report = fixture_v3(1, name)
            report['evidence']['wiring'][f's{stage}']['pairs'].clear()
            write(folder/name, report); expected[name] = (14, 15)

        report = fixture_v3(64, 'v3-opposing-theory-sign')
        answer = next(item for item in report['answers'] if item['id'] == 's4.q2')
        assert float(answer['raw']) < 0; answer['raw'] = str(abs(float(answer['raw'])))
        write(folder/'v3-opposing-theory-sign.html', report); expected['v3-opposing-theory-sign.html'] = (14, 15)

        report = fixture_v3(1, 'v3-missing-mode1')
        report['observations'] = [o for o in report['observations'] if o['id'] != 'u1']
        write(folder/'v3-missing-mode1.html', report); expected['v3-missing-mode1.html'] = (14, 15)

        report = fixture_v3(64, 'v3-wrong-parallel-branch')
        next(o for o in report['observations'] if o['id'] == 'parallel_i1')['value'] = 999999
        write(folder/'v3-wrong-parallel-branch.html', report); expected['v3-wrong-parallel-branch.html'] = (14, 15)

        report = fixture_v3(1, 'v3-empty')
        report['answers'] = []; report['observations'] = []; report['evidence']['wiring'] = {}
        write(folder/'v3-empty.html', report); expected['v3-empty.html'] = (0, 15)

        write(folder/'legacy.html', fixture('LD6', 1, 'legacy')); expected['legacy.html'] = (14, 14)
        results, seconds = run(executable, folder, root/'Vertinimas')
        assert len(results['results']) == len(expected)
        for result in results['results']:
            points, maximum = expected[result['file']]
            assert result['status'] == 'graded' and (result['points'], result['max_points']) == (points, maximum), result
        print(json.dumps(dict(status='PASS', variants=64, mna_cases=258, graded_reports=len(expected),
                              rubric_v3=15, historical_v2=25, legacy_v1=14,
                              no_measurement_retyping=True, grouped_measurements=4,
                              kirchhoff_and_power_balance=True, seconds=round(seconds, 3))))


if __name__ == '__main__': main(Path(sys.argv[1]).resolve(), Path(sys.argv[2]).resolve())
