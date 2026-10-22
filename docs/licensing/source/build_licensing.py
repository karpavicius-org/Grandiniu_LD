from pathlib import Path
import json, re, shutil, hashlib, zipfile
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.opc.constants import RELATIONSHIP_TYPE as RT

ROOT=Path(__file__).resolve().parent
OUT=ROOT/'output'
FILES=ROOT/'repo_files'
PUB=json.loads((ROOT/'evidence/PUBLICATION.json').read_text())
BASE=json.loads((FILES/'audits/licensing-20261022/BASELINE.json').read_text())
SIGN=json.loads((ROOT/'signing/public/SIGNING_KEY.json').read_text()) if (ROOT/'signing/public/SIGNING_KEY.json').exists() else None
FONT='Times New Roman'
d=Document()
s=d.sections[0]
s.page_width=Inches(8.5);s.page_height=Inches(11)
s.top_margin=Inches(.58);s.bottom_margin=Inches(.55)
s.left_margin=Inches(.68);s.right_margin=Inches(.68)
s.header_distance=Inches(.23);s.footer_distance=Inches(.23)
for p in list(d.styles.element.iter(qn('w:pBdr'))):p.getparent().remove(p)
for name in ['Normal','Title','Subtitle','Heading 1','Heading 2']:
    st=d.styles[name];st.font.name=FONT;st.font.color.rgb=RGBColor(0,0,0)
    st.element.get_or_add_rPr().rFonts.set(qn('w:eastAsia'),FONT)
n=d.styles['Normal'];n.font.size=Pt(11)
n.paragraph_format.line_spacing=1.02;n.paragraph_format.space_after=Pt(3)
n.paragraph_format.widow_control=True
d.styles['Title'].font.size=Pt(20);d.styles['Title'].font.bold=True
d.styles['Title'].paragraph_format.space_after=Pt(5)
d.styles['Subtitle'].font.size=Pt(10)
d.styles['Subtitle'].paragraph_format.space_after=Pt(6)
for name in ['Heading 1','Heading 2']:
    st=d.styles[name];st.font.size=Pt(11);st.font.bold=True
    st.paragraph_format.space_before=Pt(6);st.paragraph_format.space_after=Pt(2)
    st.paragraph_format.keep_with_next=True
header=s.header.paragraphs[0];header.alignment=WD_ALIGN_PARAGRAPH.RIGHT
r=header.add_run('GRANDINIU LD  |  RIMAS KARPAVIČIUS  |  2026 10 22');r.font.size=Pt(8)
footer=s.footer.paragraphs[0];footer.alignment=WD_ALIGN_PARAGRAPH.RIGHT
footer.add_run('EN / LT  ·  ')
f=OxmlElement('w:fldSimple');f.set(qn('w:instr'),'PAGE');footer._p.append(f)
for r in footer.runs:r.font.size=Pt(8)
d.core_properties.title='Grandiniu LD nuosavybinė licencija ir Git patikra'
d.core_properties.author='Rimas Karpavičius'
d.core_properties.subject='English and Lithuanian proprietary license with verified version evidence'
d.core_properties.language='lt-LT'

def p(text,style=None):return d.add_paragraph(text,style)
def h(text):return p(text,'Heading 1')
def mono(text):
    pp=p(text);pp.paragraph_format.space_after=Pt(5)
    for r in pp.runs:r.font.name='DejaVu Sans Mono';r.font.size=Pt(9)
    return pp
def link(label,url):
    pp=p('');hyp=OxmlElement('w:hyperlink')
    hyp.set(qn('r:id'),pp.part.relate_to(url,RT.HYPERLINK,is_external=True))
    rr=OxmlElement('w:r');pr=OxmlElement('w:rPr');color=OxmlElement('w:color');color.set(qn('w:val'),'000000');pr.append(color)
    rr.append(pr);tt=OxmlElement('w:t');tt.text=label;rr.append(tt);hyp.append(rr);pp._p.append(hyp)
    return pp

for idx,name in enumerate(['LICENSE','LICENCIJA_LT.txt']):
    if idx:d.add_page_break()
    blocks=(FILES/name).read_text().strip().split('\n\n')
    first=blocks.pop(0).splitlines()
    p('Grandiniu LD proprietary license' if idx==0 else 'Grandiniu LD nuosavybinė licencija','Title')
    p(first[1],'Subtitle')
    for block in blocks:
        lines=block.splitlines()
        if re.match(r'^\d+\.',lines[0]):
            title=re.sub(r'^(\d+)\.\s*',r'\1 ',lines[0]).replace('-',' ')
            number, words = title.split(' ',1)
            words = words[:1].upper()+words[1:].lower()
            if idx==0 and words.startswith('Ai '):words='AI '+words[3:]
            h(number+' '+words)
            p(' '.join(lines[1:]))
        else:
            for line in lines:
                pp=p(line)
                pp.paragraph_format.space_after=Pt(1)

d.add_page_break()
p('Grandiniu LD Git įrašų patikra','Title')
p('Patikrinta 2026 m. spalio 22 d.  |  Versijų ir turinio įrodymai','Subtitle')
p('Licencijos tekstai ir kilmės duomenys paskelbti esamoje darbo šakoje. Patikra patvirtina konkretaus turinio versijas ir įrašų ryšį; teisių turėtojo asmenybės, teisinės nuosavybės ar naudoto DI modelio ji neautentifikuoja.')
h('Saugykla ir šaka')
link('karpavicius-org/Grandiniu_LD','https://github.com/karpavicius-org/Grandiniu_LD')
p(PUB['branch'])
p('SSH saugyklos adresas')
mono('git@github.com:karpavicius-org/Grandiniu_LD.git')
h('Licencijos paskelbimo įrašas')
c=PUB['published_commit'];mono(c['sha'])
p('Git laikas UTC: '+c['committer']['date']+'  |  Parašo būsena: '+c['verification']['reason'])
link('Atverti paskelbtą licencijos įrašą',c['html_url'])
p('Medžio SHA');mono(PUB['tree_sha'])
h('Patikrintos ankstesnės versijos')
labels=['Patvirtintas v6 pagrindas','V7 paketas su macOS biblioteka','V7 ataskaitos antraštės pataisa']
for cc,label in zip(BASE['verified_historical_commits'],labels):
    pp=p(label+'  |  '+cc['committer']['date']);pp.paragraph_format.keep_with_next=True
    mono(cc['sha'])
h('Pakeitimų apimtis')
p('Pridėta 10 licencijos, pranešimų ir patikros failų. Visų 608 anksčiau buvusių saugyklos failų Git blob SHA liko identiški. Pradinio v7 platinimo paketo 222 failai papildytame ZIP išsaugoti baitas į baitą; pridėti tik pranešimai ir patikros duomenys.')
h('SHA ir SSH reikšmė')
p('Visi keturi čia pateikti Git įrašai nepasirašyti. SHA yra Git objekto identifikatorius. SSH ryšio autentifikavimas, Git įrašo pasirašymas ir archyvo pasirašymas yra atskiri veiksmai. Atnaujintam galutiniam archyvui taikomas SSH parašas aprašytas 5 puslapyje; jis nekeičia ankstesnių Git įrašų parašo būsenos.')

d.add_page_break()
p('Kontrolinės sumos ir teiginių pagrindas','Title')
p('SHA 256 sumos skirtos failų tapatumui tikrinti','Subtitle')
h('Pradinis v7 programos paketas')
p(BASE['artifact_checksums'][0]['file']);mono(BASE['artifact_checksums'][0]['sha256'])
h('Atskirai parengti metodiniai nurodymai')
for aa in BASE['artifact_checksums'][1:]:p(aa['file']);mono(aa['sha256'])
p('Šios dokumentų sumos užfiksuotos naujame licencijos Git įraše. Tai nereiškia, kad dokumentų PDF ir Word failai buvo ankstesnių programos Git įrašų dalis.')
h('Teisių turėtojo ir DI įrašai')
p('Rimas Karpavičius ir kontaktas karpaviciux@gmail.com įrašyti pagal užduotyje pateiktą teisių turėtojo informaciją. „GPT 6.1 Sol Ultra“ nurodytas kaip jo pateikta kūrimo deklaracija. Nepriklausomų modelio tapatybės metaduomenų patikrintoje Git istorijoje nerasta.')
h('Trečiųjų šalių komponentai')
p('Eigen 5.0.0 taikoma MPL 2.0 ir atitinkami papildomi pranešimai; JSON for Modern C++ 3.12.0 taikoma MIT. Visi šeši anksčiau pateikti licencijų tekstai išsaugoti nepakeisti. Scilab diegiamas atskirai. Windows statinių GNU ir MinGW vykdymo komponentų pranešimai pradiniame pakete nevisi atskirai dokumentuoti, todėl šis dokumentas nėra visos platinimo teisinės atitikties pažyma.')
h('Naudojimas be leidimo')
p('Pranešimas reikalauja išankstinio rašytinio leidimo teisiškai saugomai nuosavai medžiagai naudoti ir išsaugo ankstesnių licencijų, įstatymų, platformos bei trečiųjų šalių suteiktas teises. Atsakomybė kyla tik pagal taikytiną teisę; vien licencijos įrašas bausmės nesukuria.')
h('Pirminiai paaiškinimo šaltiniai')
link('Open Source Initiative  MIT License','https://opensource.org/license/mit')
link('WIPO  Copyright frequently asked questions','https://www.wipo.int/en/web/copyright/faq-copyright')
link('Git  git verify commit documentation','https://git-scm.com/docs/git-verify-commit')
p('MIT leidžia bendrą naudojimą be atskiro išankstinio leidimo. Dėl prašomo rašytinio sutikimo režimo parengta nuosavybinė licencija. Trečiųjų šalių MIT tekstai išlieka galioti savo komponentams.')

if SIGN:
    d.add_page_break()
    p('Archyvo SSH parašas','Title')
    p('Ed25519 parašas galutiniam platinimo archyvui','Subtitle')
    p('Šio leidimo archyvas pasirašomas SSH Ed25519 raktu, kai į jį jau įtrauktos galutinės šio dokumento Word ir PDF versijos. Atskiras .sig failas ir patikros priedas perduodami kartu. Parašas apima visus pasirašyto ZIP baitus ir taip pat jo viduje esančius dokumentus.')
    h('Viešojo rakto atspaudas')
    mono(SIGN['fingerprint_sha256'])
    p('Viešojo rakto failas: Grandiniu_LD_release_ed25519.pub')
    p('Pasirašančiojo žyma: '+SIGN['signer_id'])
    p('Naudojimo kontekstas namespace: '+SIGN['namespace'])
    p('Rakto sukūrimo laikas UTC: '+SIGN['created_at_utc'])
    h('Rakto kilmė ir pasitikėjimas')
    p('Tai naujas šiam projekto leidimui užduoties vykdymo aplinkoje sukurtas raktas. Jis nėra anksčiau naudotas asmeninis Rimo Karpavičiaus SSH raktas. Privatus raktas į platinamus failus ir Git neįtrauktas. Ilgalaikis privataus rakto išlikimas vykdymo aplinkoje negarantuojamas.')
    p('Atspaudas turi sutapti su patikimu kanalu gautu atspaudu. Parašas patvirtina turinio vientisumą ir atitinkamo rakto panaudojimą. Projekto žyma allowed_signers faile savaime nepatvirtina žmogaus tapatybės, teisinės nuosavybės ar nepriklausomo laiko žymens.')
    h('Tikrinimas Linux ir macOS terminale')
    p('Archyvą ir išskleistą patikros priedą laikykite tame pačiame aplanke. Jame vykdykite komandą; būtinas ssh-keygen su SSHSIG palaikymu.')
    for line in [
        'A=Grandiniu_LD_pilnas_paketas_licencija_EN_LT_2026-10-22.zip',
        'ssh-keygen -Y verify -f allowed_signers \\',
        '  -I grandiniu-ld-release-20261022 \\',
        '  -n grandiniu-ld-release -s "$A.sig" < "$A"',
    ]:
        pp=mono(line);pp.paragraph_format.space_after=Pt(0)
    p('Windows aplinkoje naudokite priede pateiktą TIKRINTI.cmd; Linux ir macOS aplinkoje galima vykdyti sh TIKRINTI.sh. Sėkmingas rezultatas yra Good ir proceso baigties kodas 0. Kitas rezultatas reiškia, kad patikra nepraėjo.')
    h('Tikslus failas ir patikros įrodymai')
    p('Galutinio archyvo SHA 256, .sig parašas ir realių patikrų rezultatai pateikiami atskirame SIGNED_RELEASE.json faile bei patikros priedo archyve. Šis dokumentas yra pasirašyto ZIP viduje, todėl jame neįrašoma to paties ZIP kontrolinė suma: ją įrašius pasikeistų paties archyvo baitai.')
    h('Archive SSH signature')
    p('The final ZIP containing this document is signed using the project release Ed25519 key identified above. The detached .sig file, public key, allowed_signers file and SIGNED_RELEASE.json are supplied separately. Verify the pinned key fingerprint before trusting the signature. This newly generated project key is not an independently authenticated personal key of Rimas Karpavičius. The signature does not change the unsigned status of the historical Git commits or certify legal ownership.')
    link('OpenSSH  ssh keygen manual','https://man.openbsd.org/ssh-keygen')

OUT.mkdir(exist_ok=True)
doc=OUT/'Grandiniu_LD_licencija_EN_LT_ir_Git_patikra.docx'
d.save(doc)
print(json.dumps({'docx':str(doc),'paragraphs':len(d.paragraphs)},ensure_ascii=False))
