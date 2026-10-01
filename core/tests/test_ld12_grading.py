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


def main(executable):
    for number in range(1, 65):
        ul, r = variant_values(number)
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
                              sqrt3_relations=True, power_formulas_agree=True, seconds=round(seconds, 3))))


if __name__ == '__main__': main(Path(sys.argv[1]).resolve())
