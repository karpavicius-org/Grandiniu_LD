"""Internal feedback: readable native exports, versioned scoring and practice."""
import copy
import ctypes as c
from html.parser import HTMLParser
import json
from pathlib import Path
import sys
import tempfile
from test_grading import fixture, write, run

class Visible(HTMLParser):
    def __init__(self): super().__init__(); self.script=False; self.text=''
    def handle_starttag(self,tag,attrs):
        if tag=='script': self.script=True
    def handle_endtag(self,tag):
        if tag=='script': self.script=False
    def handle_data(self,data):
        if not self.script: self.text+=data+' '

lib=c.CDLL(str(Path(sys.argv[1]).resolve())); grader=Path(sys.argv[2]).resolve()
def ints(s):
    b=s.encode('utf-8'); return (c.c_int*len(b))(*b),c.c_int(len(b))
with tempfile.TemporaryDirectory(prefix='LD pristatymas Žąsė ') as tmp:
    root=Path(tmp); folder=root/'reports';folder.mkdir()
    expected={}
    for n in range(1,65):
        r=fixture('LD1',n,f'guided-{n}');r['lab_revision']='2';r['rubric_version']='LD1-2'
        r['evidence']['automatic_setup']=True
        for case in ['correct','wrong','missing_observation']:
            a=copy.deepcopy(r);a['submission_id']+=case
            if case=='wrong': a['answers'][0]['raw']='999999'
            if case=='missing_observation':a['observations'][0]['value']=None
            path=folder/f'{n}-{case}.html';p,np=ints(str(path));b,nb=ints(json.dumps(a,ensure_ascii=False));status=c.c_int(-1)
            lib.ld_export_report(p,c.byref(np),b,c.byref(nb),c.byref(status));assert status.value==0
            text=path.read_text(encoding="utf-8");v=Visible();v.feed(text)
            assert 's2.q1' not in v.text and 'choice' not in v.text and 'Nuosekli' in v.text
            assert 'Vertinami 15 studento atsakymų' in v.text
            expected[path.name]=(14 if case!='correct' else 15,15)
    for lab in ['LD1','LD2','LD3','LD4','LD5','LD6','LD7']:
        r=fixture(lab,17,'legacy-'+lab);path=folder/(lab+'.html');write(path,r)
        expected[path.name]=({'LD1':22,'LD2':50,'LD3':15,'LD4':27,'LD5':16,'LD6':18,'LD7':27}[lab],None)
    data,_=run(grader,folder,root/'graded')
    for result in data['results']:
        assert result['status']=='graded',result
        points,maximum=expected[result['file']]
        if maximum is not None:
            assert (result['points'],result['max_points'])==(points,maximum),result
            automatic=[i for i in result['items'] if i.get('automatic')]
            assert len(automatic)==7 and all(i['max_points']==i['points']==0 for i in automatic)
        elif result['lab_id']=='LD1':assert result['max_points']==22
    attempts=root/'attempts';attempts.mkdir()
    for name,mode,practice in [('assessment','assessment',False),('practice','assessment',True),('learning','learning',False)]:
        r=fixture('LD1',1,name);r['student']['name']='Tas Pats';r['mode']=mode;r['practice_used']=practice
        write(attempts/(name+'.html'),r)
    data,_=run(grader,attempts,root/'attempt-verdicts')
    assert [r['file'] for r in data['results'] if r['selected_for_summary']]==['assessment.html']
    reasoning=root/'reasoning';reasoning.mkdir()
    for agrees in [False,True]:
        r=fixture('LD1',17,'own-kcl-'+str(agrees))
        for answer in r['answers']:
            if answer['id']=='s8.q1':answer['raw']='99999'
            if answer['id']=='s8.compare':answer['raw']='1' if agrees else '2'
        write(reasoning/(str(agrees)+'.html'),r)
    data,_=run(grader,reasoning,root/'reasoning-verdicts')
    for result in data['results']:
        comparison=next(i for i in result['items'] if i['id']=='s8.compare')
        assert comparison['points']==(0 if result['file']=='True.html' else 1),result
    bad,nb=ints(str(root/'nonexistent.html'));status=c.c_int(0)
    lib.ld_open_local(bad,c.byref(nb),c.byref(status));assert status.value<0
print('PASS: 64 guided variants, legacy reports, readable exports, zero automatic points, practice excluded')
