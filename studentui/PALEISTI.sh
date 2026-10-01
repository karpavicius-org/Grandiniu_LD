#!/usr/bin/env bash
set -eu
bench_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
case "$(uname -s)" in
  Darwin) bench_core="$bench_dir/bin/ldcore.dylib" ;;
  *)      bench_core="$bench_dir/bin/ldcore.so" ;;
esac
if [ ! -f "$bench_core" ]; then
    printf '%s\n' "Trūksta $bench_core. Išskleiskite visą savo platformos paketą." >&2
    exit 1
fi
bench_scilab=${SCILAB_BIN:-}
if [ -z "$bench_scilab" ]; then
    if [ "$(uname -s)" = Darwin ]; then
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
    printf '%s\n' 'Scilab nerastas. Reikalingas Scilab 2026.1.0; atverkite STENDAS.sce arba nurodykite SCILAB_BIN.' >&2
    exit 1
fi
if [ "$(uname -s)" = Darwin ]; then
    PATH="$(dirname -- "$bench_scilab"):$PATH"
    export PATH
fi
exec "$bench_scilab" -f "$bench_dir/STENDAS.sce"
