import copy
import json
import math
from pathlib import Path
import sys
import tempfile
from test_grading import fixture, write, run


def variant_values(number):
    row, col = divmod(number - 1, 8)
    r1 = round([100, 120, 150, 180, 220, 270, 330, 390][row] * (1 + (number % 11 - 5) / 100) * 10) / 10
    r2 = round([470, 560, 680, 820, 1000, 1200, 1500, 1800][col] * (1 + ((3 * number) % 11 - 5) / 100) * 10) / 10
    r3 = round([220, 270, 330, 390, 470, 560, 680, 820][(row + col) % 8] * (1 + ((5 * number) % 11 - 5) / 100) * 10) / 10
    return r1, r2, r3


def fixture_v2(number, identity):
    """Build a complete LD8-2 report from physical measurements and theory."""
    report = fixture('LD8', number, identity)
    meaningful = {"s2.q1", "s3.q1", "s4.q1", "s5.q1", "s5.q2", "s5.q3",
                  "s6.q1", "s6.q2", "s6.q3"}
    report['answers'] = [a for a in report['answers'] if a['id'] in meaningful]
    assert len(report['answers']) == 9
    report['lab_revision'] = '2'
    report['rubric_version'] = 'LD8-2'
    return report


def main(executable):
    # Independent Kirchhoff/resistance checks, for all 64 variant combinations.
    for number in range(1, 65):
        r1, r2, r3 = variant_values(number)
        series = r1 + r2 + r3
        parallel = 1 / (1 / r1 + 1 / r2 + 1 / r3)
        mixed = r1 + r2 * r3 / (r2 + r3)
        assert series > max(r1, r2, r3)
        assert parallel < min(r1, r2, r3)
        assert parallel < mixed < series
        currents = [12 / x * 1000 for x in [series, parallel, mixed]]
        assert currents[1] > currents[2] > currents[0]
        branches = [12 / x * 1000 for x in [r1, r2, r3]]
        assert math.isclose(sum(branches), currents[1], rel_tol=1e-12)
        # All three valid resistor arrangements obey E = I*R.
        for resistance, current in zip([series, parallel, mixed], currents):
            assert math.isclose(resistance*current / 1000, 12, rel_tol=1e-12)

    with tempfile.TemporaryDirectory(prefix='LD8 Žąsė ') as temporary:
        root = Path(temporary); folder = root / 'Darbai'; folder.mkdir()
        expected = {}
        for number in range(1, 65):
            for name, report, full in [
                (f'old-{number:02d}.html', fixture('LD8', number, f'old-{number}'), 21),
                (f'new-{number:02d}.html', fixture_v2(number, f'new-{number}'), 15),
            ]:
                if number % 2:
                    for wiring in report['evidence']['wiring'].values():
                        wiring['pairs'] = [pair[::-1] for pair in wiring['pairs'][::-1]]
                write(folder / name, report); expected[name] = (full, full)

        for stage in ['s1', 's3', 's4']:
            for damage in ['missing', 'duplicate', 'extra_endpoint']:
                report = fixture_v2(1, f'{stage}-{damage}')
                pairs = report['evidence']['wiring'][stage]['pairs']
                if damage == 'missing': pairs.pop()
                elif damage == 'duplicate': pairs[-1] = copy.deepcopy(pairs[0])
                else: pairs[0].append('R3_B')
                name=f'new-{stage}-{damage}.html'
                write(folder / name, report); expected[name] = (14, 15)

        for missing in ['u2', 'i2']:
            report = fixture_v2(17, f'missing-{missing}')
            report['observations'] = [o for o in report['observations'] if o['id'] != missing]
            name = f'new-no-{missing}.html'
            write(folder / name, report); expected[name] = (14, 15)

        report = fixture_v2(17, 'both-bad')
        for obs in report['observations']:
            if obs['id'] in {'u2', 'i2'}:
                obs['value'] = 12345678
        write(folder / 'new-both-bad.html', report)
        expected['new-both-bad.html'] = (14, 15)  # one real action, one lost point

        for label, factor in [('inside', 1.0099), ('outside', 1.0101)]:
            report = fixture_v2(17, label)
            next(a for a in report['answers'] if a['id'] == 's2.q1')['raw'] = format(
                float(next(a for a in report['answers'] if a['id'] == 's2.q1')['raw']) * factor, '.17g')
            name=f'new-boundary-{label}.html'
            write(folder/name, report); expected[name]=(15 if label=='inside' else 14,15)

        report = fixture_v2(23, 'u-too-far')
        next(o for o in report['observations'] if o['id']=='u2')['value'] += 0.006
        write(folder/'new-u-too-far.html', report); expected['new-u-too-far.html']=(14,15)

        report=fixture_v2(17,'bad-current')
        next(a for a in report['answers'] if a['id']=='s5.q2')['raw']='not-a-number'
        write(folder/'new-bad-current.html', report);expected['new-bad-current.html']=(14,15)

        report=fixture_v2(17,'wrong-conclusion')
        next(a for a in report['answers'] if a['id']=='s6.q2')['raw']='2'
        write(folder/'new-wrong-conclusion.html', report);expected['new-wrong-conclusion.html']=(14,15)

        report = fixture_v2(64, 'empty')
        report['answers'] = []; report['observations'] = []; report['evidence']['wiring'] = {}
        write(folder/'new-empty.html', report); expected['new-empty.html']=(0,15)

        old = fixture('LD8', 17, 'old-wrong')
        next(a for a in old['answers'] if a['id'] == 's2.q2')['raw'] = '999999'
        write(folder/'old-wrong.html', old); expected['old-wrong.html']=(20,21)

        results, seconds = run(executable, folder, root/'Vertinimas')
        assert len(results['results']) == len(expected), (len(results['results']),len(expected))
        for result in results['results']:
            assert result['status'] == 'graded', result
            assert (result['points'], result['max_points']) == expected[result['file']], result
        print(json.dumps(dict(status='PASS', variants=64, graded_reports=len(expected),
                              rubric_v2=15, legacy_rubric_v1=21, grouped_measurements=3,
                              no_copied_resistance_fields=True, kirchhoff=True,
                              seconds=round(seconds,3))))


if __name__ == '__main__':
    main(Path(sys.argv[1]).resolve())
