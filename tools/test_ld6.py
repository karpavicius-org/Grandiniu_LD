#!/usr/bin/env python3
"""Internal feedback only: bounded native Scilab LD6 UI acceptance on both OSes."""
import argparse
import json
import sys
import os
from pathlib import Path
import shutil
import subprocess

p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--scilab', required=True, type=Path)
p.add_argument('--checker', required=True, type=Path)
p.add_argument('--core', type=Path)
p.add_argument('--grader', required=True, type=Path)
p.add_argument('--output', required=True, type=Path)
a = p.parse_args()
repo = Path(__file__).resolve().parents[1]
out = a.output.resolve(); out.mkdir(parents=True, exist_ok=True)
runtime = out / 'runtime' / 'studentui'
shutil.copytree(repo / 'studentui', runtime, ignore=shutil.ignore_patterns('results', '__pycache__'))
(runtime / 'tests/results').mkdir(parents=True)
env = dict(os.environ, LD6_TEST_RUNTIME=runtime.as_posix(), LD6_TEST_OUT=out.as_posix(),
           LD6_TEST_SOURCE=repo.as_posix(), LD_DATA_DIR=(out / 'Ataskaitos Žąsė').as_posix())
if a.core: env['LD_CORE_LIBRARY'] = str(a.core.resolve())
exe = a.scilab.resolve()
if os.name == 'nt':
    exe = exe.parent / 'WScilex-cli.exe'
    assert exe.is_file(), f'Missing graphical Scilab executable: {exe}'
# Windows uses separate STD/NW/NWNI binaries, without -nw/-nwni flags.
mode = [] if os.name == 'nt' else ['-nw']
args = [str(exe), *mode, '-nb', '-f', str(repo / 'tools/test_ld6.sce')]
with (out / 'scilab.log').open('wb') as log:
    result = subprocess.run(args, env=env, stdout=log, stderr=subprocess.STDOUT, timeout=240)
verdict = (out / 'verdict.log').read_text(encoding='utf-8') if (out / 'verdict.log').exists() else (out / 'scilab.log').read_text(encoding='utf-8', errors='replace')
assert result.returncode == 0 and 'LD6_PASS:' in verdict, verdict
print(verdict.strip())
result = subprocess.run([str(a.checker.resolve()), str(out / 'geometry.tsv')], capture_output=True, text=True)
(out / 'geometry.log').write_text(result.stdout + result.stderr, encoding='utf-8')
print(result.stdout)
assert result.returncode == 0, 'LD6 geometry failed'

# Compare the actual Scilab step decisions with C++ grading of the same reports.
sys.path.insert(0, str(repo / 'core/tests'))
from test_grading import write, run
cases = json.loads((out / 'tolerance-cases.json').read_text(encoding='utf-8'))
inputs = out / 'boundary-reports'; inputs.mkdir()
expected = {}
for index, case in enumerate(cases):
    name = f'{index:03d}.html'
    write(inputs / name, case['report'])
    expected[name] = 25 if case['accepted'] else 24
verdicts, _ = run(a.grader.resolve(), inputs, out / 'boundary-grading')
assert len(verdicts['results']) == len(expected)
for result in verdicts['results']:
    assert result['status'] == 'graded' and result['max_points'] == 25, result
    assert result['points'] == expected[result['file']], result
actual, _ = run(a.grader.resolve(), out / 'Ataskaitos Žąsė', out / 'student-grading')
reports = [r for r in actual['results'] if r['file'].endswith('.html')]
drafts = [r for r in actual['results'] if r['file'].endswith('.sod')]
assert len(reports) == 3 and len(drafts) >= 3
assert len(actual['results']) == len(reports) + len(drafts)
for result in reports:
    assert result['status'] == 'graded' and (result['points'], result['max_points']) == (25, 25), result
    assert result['mode'] == 'assessment' and result['selected_for_summary'] and not result['practice_used'], result
for result in drafts:
    assert result['status'] == 'review' and result['reason'] == 'unsupported_file' and result['grade_10'] is None, result
summary = dict(status='PASS', tolerance_cases=len(expected), actual_gui_reports=3,
               variants=[1, 17, 64], geometry_cases=39, assessment_reports_selected=True,
               autosave_restore_close=True, platform=os.name)
(out / 'acceptance.json').write_text(json.dumps(summary, indent=2)+'\n', encoding='utf-8')
print(json.dumps(summary))
