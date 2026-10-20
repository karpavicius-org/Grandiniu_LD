#!/usr/bin/env python3
"""Create independent student and teacher distributions from a tested native CI ZIP.

No executable is renamed, modified, obscured, or recompiled.  Both profiles
preserve the Scilab files; only the unneeded teacher command-line programs are
omitted from the student archive.  The native release manifest is verified
before and after separation.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import zipfile

ROOT = 'Grandiniu_LD/'
LABS = [f'LD{k}' for k in range(1, 13)]
PLATFORMS = {
    'Windows': ('ldcore.dll', 'ldcheck.exe', 'mokytojas.exe'),
    'Linux': ('ldcore.so', 'ldcheck', 'mokytojas'),
    'macOS-arm64': ('ldcore.dylib', 'ldcheck', 'mokytojas'),
    'macOS-x86_64': ('ldcore.dylib', 'ldcheck', 'mokytojas'),
}
PROFILES = {'Studentas': ('Studentas',), 'Destytojas': ('Destytojas',)}
MAX_UNCOMPRESSED = 128 * 1024 * 1024


class PackageError(ValueError):
    pass


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def members(z: zipfile.ZipFile) -> dict[str, bytes]:
    names = z.namelist()
    if len(names) != len(set(names)):
        raise PackageError('Duplicate ZIP paths')
    total = sum(i.file_size for i in z.infolist())
    if total > MAX_UNCOMPRESSED:
        raise PackageError('Uncompressed ZIP size exceeds safety limit')
    for item in z.infolist():
        name = item.filename
        path = PurePosixPath(name)
        if ('\\' in name or '\x00' in name or path.is_absolute()
                or '..' in path.parts or not name.startswith(ROOT)):
            raise PackageError(f'Unsafe ZIP path: {name}')
        # Do not distribute symbolic links or encrypted content from an untrusted ZIP.
        if (item.external_attr >> 16) & 0o170000 == 0o120000 or item.flag_bits & 1:
            raise PackageError(f'Unsupported ZIP entry: {name}')
    if z.testzip() is not None:
        raise PackageError('Bad ZIP checksum')
    return {n: z.read(n) for n in names if not n.endswith('/')}


def load_release(payload: dict[str, bytes], platform: str, *, profile: str | None = None) -> dict:
    try:
        r = json.loads(payload[ROOT + 'RELEASE.json'])
    except (KeyError, ValueError) as exc:
        raise PackageError('Missing/invalid release manifest') from exc
    if r.get('platform') != platform or r.get('labs') != LABS:
        raise PackageError('Incorrect platform or missing LD1-LD12 in manifest')
    if profile is None:
        if r.get('schema_version') != 1:
            raise PackageError('Expected original CI release schema 1')
    elif r.get('schema_version') != 2 or r.get('profile') != profile:
        raise PackageError('Wrong separated release schema/profile')
    if not isinstance(r.get('source_commit'), str) or len(r['source_commit']) != 40:
        raise PackageError('Invalid source commit')
    expected = PLATFORMS[platform][:1] if profile == 'Studentas' else PLATFORMS[platform]
    expected_set = set(expected)
    hashes = r.get('binaries_sha256')
    if not isinstance(hashes, dict) or set(hashes) != expected_set:
        raise PackageError('Incorrect binary manifest')
    real = {p[len(ROOT + 'bin/'):]: p for p in payload if p.startswith(ROOT + 'bin/')}
    if set(real) != expected_set:
        raise PackageError('Unexpected/missing binary in package')
    for name, sha in hashes.items():
        if digest(payload[real[name]]) != sha:
            raise PackageError(f'Binary digest mismatch: {name}')
    required = [ROOT + name for name in (
        'STENDAS.sce', 'DESTYTOJUI.sce', 'PALEISTI.bat', 'PALEISTI.sh',
        'PALEISTI.command', 'README.md', 'bench_common.sci', 'bench_teacher.sci')]
    required += [ROOT + f'LD{i}/VARIANTAI.csv' for i in range(1, 13)]
    if any(name not in payload for name in required):
        raise PackageError('Missing laboratory or teacher Scilab files')
    if profile == 'Studentas' and any(p.lower().endswith(('.exe', '.com', '.scr', '.pif')) for p in payload):
        raise PackageError('Student distribution unexpectedly contains an executable')
    return r


def profile_notes(profile: str, platform: str) -> bytes:
    common = ('Grandinių LD1–LD12 | ' + profile + ' | ' + platform + '\n\n'
        'Scilab 2026.1.0 turi būti įdiegtas atskirai.\n'
        'Studentui: Windows – PALEISTI.bat; Linux – PALEISTI.sh; '
        'macOS – PALEISTI.command.\n'
        'Kitas būdas: Scilab atidaryti STENDAS.sce.\n'
        'Vietinis dėstytojo ataskaitų vertinimas: Scilab atidaryti '
        'DESTYTOJUI.sce, nurodyti ataskaitų aplanką.\n'
        'LD1–LD12 skaičiavimo ir vertinimo algoritmai nekeičiami.\n\n')
    if profile == 'Studentas':
        specifics = ('Šiame pakete pateiktas tik būtinas natyvus skaičiavimo branduolys.\n'
            'Atskiros komandinės programos ldcheck ir mokytojas NEĮTRAUKTOS.\n'
            'Automatinis vietinių ataskaitų vertinimas per Scilab VEIKIA.\n'
            'Google Drive masinis importas per mokytojas programą prieinamas '
            'atskirame dėstytojo pakete.\n')
    else:
        specifics = ('Šiame pakete pateikti ldcore, ldcheck ir mokytojas.\n'
            'Papildomas dėstytojo įrankis: bin/mokytojas '
            '(Windows: bin\\mokytojas.exe).\n'
            'Jis gali apdoroti vietinį aplanką arba Google Drive nuorodą '
            '(reikalingas API raktas ir prieiga).\n'
            'Visas mokytojo funkcionalumas išsaugotas.\n')
    return (common + specifics + '\nDėl saugumo įspėjimų neapeikite antivirusinės apsaugos.\n').encode('utf-8')


def write_entry(z: zipfile.ZipFile, name: str, data: bytes, old: zipfile.ZipInfo | None = None) -> None:
    if old is None:
        info = zipfile.ZipInfo(name, (1980, 1, 1, 0, 0, 0))
        info.create_system = 3
        info.external_attr = 0o100644 << 16
        info.compress_type = zipfile.ZIP_DEFLATED
    else:
        # Copy metadata so shell launchers retain their executable permissions.
        info = zipfile.ZipInfo(name, old.date_time)
        info.create_system = old.create_system
        info.external_attr = old.external_attr
        info.compress_type = zipfile.ZIP_DEFLATED
    z.writestr(info, data, compresslevel=9)


def separate(original: Path, outdir: Path, platform: str) -> list[Path]:
    if platform not in PLATFORMS:
        raise PackageError(f'Unsupported platform: {platform}')
    original = original.resolve()
    with zipfile.ZipFile(original) as src:
        payload = members(src)
        release = load_release(payload, platform)
        metadata = {n: src.getinfo(n) for n in payload}
    sha = digest(original.read_bytes())
    outdir.mkdir(parents=True, exist_ok=True)
    targets = []
    for profile in PROFILES:
        needed = set(PLATFORMS[platform][:1] if profile == 'Studentas' else PLATFORMS[platform])
        excluded = {ROOT + 'bin/' + name for name in set(PLATFORMS[platform]) - needed}
        subset = {n: data for n, data in payload.items()
                  if n not in excluded and n != ROOT + 'RELEASE.json'}
        manifest = dict(release)
        manifest['schema_version'] = 2
        manifest['profile'] = profile
        manifest['base_package_sha256'] = sha
        manifest['binaries_sha256'] = {n: release['binaries_sha256'][n] for n in sorted(needed)}
        subset[ROOT + 'RELEASE.json'] = (json.dumps(manifest, ensure_ascii=False, indent=2) + '\n').encode('utf-8')
        subset[ROOT + 'PAKETAS.txt'] = profile_notes(profile, platform)
        name = f'Grandiniu_LD-{profile}-{platform}.zip'
        target = outdir / name
        temp = target.with_suffix('.zip.tmp')
        with zipfile.ZipFile(temp, 'w') as z:
            for entry in sorted(subset):
                write_entry(z, entry, subset[entry], metadata.get(entry))
        with zipfile.ZipFile(temp) as z:
            candidate = members(z)
            verified = load_release(candidate, platform, profile=profile)
            if verified['base_package_sha256'] != sha:
                raise PackageError('Source archive provenance mismatch')
            for entry in set(payload) - excluded - {ROOT + 'RELEASE.json'}:
                if candidate[entry] != payload[entry]:
                    raise PackageError(f'Unexpected source modification: {entry}')
            if candidate[ROOT + 'PAKETAS.txt'] != profile_notes(profile, platform):
                raise PackageError('Bad package instructions')
        temp.replace(target)
        targets.append(target)
        print(f'PASS: {target} ({len(candidate)} entries; SHA256={digest(target.read_bytes())})')
    return targets


def cli():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--platform', choices=PLATFORMS, required=True)
    parser.add_argument('--input', type=Path, help='Native full CI archive; defaults to dist/Grandiniu_LD-PLATFORM.zip')
    parser.add_argument('--out-dir', type=Path, default=Path('dist'))
    args = parser.parse_args()
    archive = args.input or Path('dist') / f'Grandiniu_LD-{args.platform}.zip'
    separate(archive, args.out_dir, args.platform)


if __name__ == '__main__':
    cli()
