"""LD1 measurement rubric: human answers, automatic data and legacy delivery."""
import copy
import ctypes
import json
from pathlib import Path
import sys
import tempfile
from test_grading import fixture, write, run


def measurement_fixture(n, identity):
    r = fixture('LD1', n, identity)
    r.update(lab_revision='3', rubric_version='LD1-3')
    r['evidence'].update(measurement_workflow=True, automatic_measurement=True, automatic_setup=False)
    r['answers'] = [a for a in r['answers'] if a['id'] in {'s1.type','s5.type','s3.compare','s6.compare','s8.compare'}]
    r['answers'] += [dict(id='s4.change', raw='1', unit='choice'), dict(id='s7.change', raw='3', unit='choice')]
    p = r['parameters']
    for key, value in [('s3.r1',10000/(p['R1']+1000)), ('s3.vr1',10000/(p['R1']+1000)),
                       ('s8.r3',10000/p['R3']), ('s8.r2',10000/p['R2'])]:
        r['observations'].append(dict(id=key,value=value,unit='mA'))
    return r


if __name__ == '__main__':
    with tempfile.TemporaryDirectory(prefix='ld1-measure-') as tmp:
        root=Path(tmp); source=root/'reports'; source.mkdir()
        for n in [1,17,64]: write(source/f'correct-{n}.html',measurement_fixture(n,f'correct-{n}'))
        wrong=measurement_fixture(17,'wrong-all-human')
        for a in wrong['answers']: a['raw']='2' if a['raw']=='1' else '1'
        write(source/'wrong-all-human.html',wrong)
        missing=measurement_fixture(17,'missing-probe')
        next(o for o in missing['observations'] if o['id']=='s3.r1')['value']=None
        write(source/'missing-probe.html',missing)
        learning=measurement_fixture(17,'learning'); learning['mode']='learning'; learning['practice_used']=True
        learning['evidence']['automatic_setup']=True; write(source/'learning.html',learning)
        unknown=measurement_fixture(17,'unknown'); unknown['answers'].append(dict(id='s2.q1',raw='1330',unit='Ohm'))
        write(source/'unknown.html',unknown)
        write(source/'legacy.html',fixture('LD1',17,'legacy'))
        results,_=run(Path(sys.argv[1]),source,root/'graded')
        by_name={r['file']:r for r in results['results']}
        for n in [1,17,64]: assert (by_name[f'correct-{n}.html']['points'],by_name[f'correct-{n}.html']['max_points'])==(9,9)
        wrong=by_name['wrong-all-human.html']; assert (wrong['points'],wrong['max_points'],wrong['grade_10'])==(2,9,2.2)
        assert by_name['missing-probe.html']['points']==8
        assert (by_name['learning.html']['points'],by_name['learning.html']['max_points'])==(7,7)
        assert not by_name['learning.html']['selected_for_summary']
        assert by_name['unknown.html']['status']=='review'
        assert by_name['legacy.html']['points']==22
        for r in by_name.values():
            if r.get('rubric_version')=='LD1-3':
                automatic=[item for item in r['items'] if item.get('automatic')]
                assert len(automatic)>=9 and all(item['points']==item['max_points']==0 for item in automatic)
        # The visible report must render direction choices as words, with no calculation tasks.
        dll=ctypes.CDLL(str(Path(sys.argv[2]).resolve())); dll.ld_export_report.argtypes=[ctypes.POINTER(ctypes.c_int)]*5
        report=measurement_fixture(17,'visible'); path=root/'visible.html'
        def buf(value): return (ctypes.c_int*len(value))(*value),ctypes.c_int(len(value))
        p,np=buf(str(path).encode('utf-8')); data,nd=buf(json.dumps(report,ensure_ascii=False).encode('utf-8')); status=ctypes.c_int(-1)
        dll.ld_export_report(p,ctypes.byref(np),data,ctypes.byref(nd),ctypes.byref(status)); assert status.value==0
        visible=path.read_text(encoding='utf-8').split('<script')[0]
        assert 'Padidėjo' in visible and 'Nepakito' in visible and 'virtualiuose matavimo taškuose' in visible
        assert 's2.q1' not in visible and 'bendroji varža' not in visible
        print('PASS: measured LD1 delivery, 9 human criteria, wrong conclusions 2/9, missing evidence, learning exclusion, legacy compatibility')
