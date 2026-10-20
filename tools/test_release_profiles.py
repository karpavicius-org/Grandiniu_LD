#!/usr/bin/env python3
"""Release-profile acceptance with independent positive and negative ZIP cases."""
from __future__ import annotations
import argparse
import hashlib
import io
import json
from pathlib import Path
import tempfile
import warnings
import zipfile
from split_release import ROOT, LABS, PLATFORMS, PackageError, digest, load_release, members, separate, profile_notes


def require_failure(archive: Path, platform: str, reason: str) -> None:
    try:
        with zipfile.ZipFile(archive) as z:
            load_release(members(z), platform)
    except (PackageError, zipfile.BadZipFile, KeyError, ValueError):
        return
    raise AssertionError('Unsafe/tampered base archive accepted: ' + reason)


def mutate(original: Path, destination: Path, change=None, extra=None):
    with zipfile.ZipFile(original) as inp, zipfile.ZipFile(destination, 'w') as out:
        for name in inp.namelist():
            contents = inp.read(name)
            if change and name == change[0]:
                contents = change[1](contents)
            out.writestr(inp.getinfo(name), contents)
        if extra:
            out.writestr(extra[0], extra[1])


def check_profile(original: Path, destination: Path, platform: str, profile: str) -> None:
    with zipfile.ZipFile(original) as z:
        source = members(z)
        from_manifest = load_release(source, platform)
    with zipfile.ZipFile(destination) as z:
        output = members(z)
        manifest = load_release(output, platform, profile=profile)
        for launcher in ['PALEISTI.sh', 'PALEISTI.command', 'PATIKRINTI.sh']:
            name = ROOT + launcher
            if name in output and not ((z.getinfo(name).external_attr >> 16) & 0o111):
                raise AssertionError('Lost executable permission: ' + launcher)
    assert manifest['source_commit'] == from_manifest['source_commit']
    assert manifest['base_package_sha256'] == digest(original.read_bytes())
    assert output[ROOT+'PAKETAS.txt'] == profile_notes(profile, platform)
    omitted = set(PLATFORMS[platform][1:]) if profile == 'Studentas' else set()
    expected = set(source) - {ROOT+'bin/'+n for n in omitted} | {ROOT+'PAKETAS.txt'}
    assert set(output) == expected, {'missing':sorted(expected-set(output)), 'unexpected':sorted(set(output)-expected)}
    for name in expected - {ROOT+'RELEASE.json', ROOT+'PAKETAS.txt'}:
        assert output[name] == source[name], f'Altered runtime or executable: {name}'
    # Independent cross-platform proof: same experiment tables and same entry points.
    for lab in LABS:
        assert (ROOT + f'{lab}/VARIANTAI.csv') in output
        assert (ROOT + f'{lab}/{lab}.sce') in output
    assert ROOT+'DESTYTOJUI.sce' in output and ROOT+'bench_teacher.sci' in output
    assert not (profile == 'Studentas' and any(n.endswith('.exe') for n in output))


def test_negative_cases(original: Path, platform: str, temp: Path) -> None:
    with zipfile.ZipFile(original) as z:
        name = ROOT+'bin/'+PLATFORMS[platform][0]
        original_exe = z.read(name)
    cases = [
        ('binary-byte-tamper', (name, lambda b:b[:-1]+bytes([b[-1]^1])), None),
        ('wrong-commit', (ROOT+'RELEASE.json', lambda b:b.replace(b'"source_commit"',b'"another_commit"')), None),
        ('unexpected-executable', None, (ROOT+'bin/extra.exe', b'NON_EXECUTABLE_TEST')), 
        ('traversal', None, (ROOT+'../unsafe.txt', b'TEST')),
    ]
    for case, change, extra in cases:
        output = temp/(case+'.zip')
        mutate(original, output, change=change, extra=extra)
        require_failure(output, platform, case)
    corrupt = temp/'bad_crc.zip'
    mutate(original, corrupt, change=(name, lambda b:b+b'xyz'))
    require_failure(corrupt, platform, 'binary-digest')
    dupe = temp/'duplicate.zip'
    with warnings.catch_warnings():
        warnings.simplefilter('ignore', UserWarning)
        with zipfile.ZipFile(original) as src, zipfile.ZipFile(dupe, 'w') as target:
            for n in src.namelist():
                target.writestr(src.getinfo(n), src.read(n))
            target.writestr(name, original_exe)
    require_failure(dupe, platform, 'duplicate-entries')


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--platform', choices=PLATFORMS, required=True)
    p.add_argument('--input', type=Path, required=True)
    p.add_argument('--out-dir', type=Path)
    args = p.parse_args()
    with tempfile.TemporaryDirectory(prefix='LD-release-test-') as dirname:
        tmp = Path(dirname)
        destination = args.out_dir or tmp/'profiles'
        separated = separate(args.input, destination, args.platform)
        assert len(separated) == 2
        for profile, target in zip(['Studentas', 'Destytojas'], separated):
            check_profile(args.input, target, args.platform, profile)
        test_negative_cases(args.input, args.platform, tmp)
        assert digest(separated[0].read_bytes()) != digest(separated[1].read_bytes())
    print(f'PASS: {args.platform}: 2 full validated distributions, LD1-LD12, teacher entry, 6 negative tests')


if __name__ == '__main__':
    main()
