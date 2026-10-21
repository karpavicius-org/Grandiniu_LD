#!/usr/bin/env bash
set -eu
bench_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
bench_os=$(uname -s)
case "$bench_os" in
  Darwin) bench_core="$bench_dir/bin/ldcore.dylib" ;;
  Linux)  bench_core="$bench_dir/bin/ldcore.so" ;;
  *) printf '%s\n' 'Šis paleidiklis skirtas macOS ir Linux. Windows naudokite PALEISTI.bat.' >&2; exit 1 ;;
esac
bench_core=${LD_CORE_LIBRARY:-$bench_core}
if [ ! -f "$bench_core" ]; then
    printf '%s\n' "Trūksta $bench_core. Išskleiskite visą savo platformos paketą." >&2
    exit 1
fi
bench_scilab=${SCILAB_BIN:-}
if [ -z "$bench_scilab" ]; then
    if [ "$bench_os" = Darwin ]; then
        for app in /Applications/*[Ss]cilab*.app "$HOME"/Applications/*[Ss]cilab*.app; do
            [ -d "$app/Contents" ] || continue
            candidate=$(find "$app/Contents" -type f -name scilab -print -quit)
            if [ -n "$candidate" ] && [ -x "$candidate" ]; then bench_scilab=$candidate; break; fi
        done
    fi
fi
if [ -z "$bench_scilab" ]; then
    bench_scilab=$(command -v scilab || true)
fi
if [ -z "$bench_scilab" ]; then
    for candidate in "$HOME"/Downloads/scilab-*/bin/scilab /tmp/scilab-clean-*/scilab-*/bin/scilab; do
        if [ -x "$candidate" ]; then bench_scilab=$candidate; break; fi
    done
fi
if [ -z "$bench_scilab" ] || [ ! -x "$bench_scilab" ]; then
    printf '%s\n' 'Scilab nerastas. Įdiekite grafinį Scilab į Applications / Programos ir paleiskite dar kartą. Jei Scilab įdiegtas kitoje vietoje, atverkite STENDAS.sce jo lange arba nurodykite SCILAB_BIN.' >&2
    exit 1
fi
if [ "$bench_os" = Darwin ]; then
    PATH="$(dirname -- "$bench_scilab"):$PATH"
    case "$bench_scilab" in
      *.app/Contents/*)
        bench_contents=${bench_scilab%%.app/Contents/*}.app/Contents
        bench_cli=$(find "$bench_contents" -type f -name scilab-cli-bin -print -quit)
        if [ -n "$bench_cli" ]; then PATH="$(dirname -- "$bench_cli"):$PATH"; fi
        ;;
    esac
    export PATH
fi
LD_CORE_LIBRARY=$bench_core
export LD_CORE_LIBRARY
exec "$bench_scilab" -f "$bench_dir/STENDAS.sce"
