#!/bin/bash
set -eu
bench_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if /bin/bash "$bench_dir/PALEISTI.sh"; then
    exit 0
else
    bench_status=$?
    if [ -t 0 ]; then
        printf '\n%s\n' 'Paleidimo pranešimas pateiktas aukščiau. Paspauskite Enter, kad užvertumėte langą.'
        read -r bench_answer || true
    fi
    exit "$bench_status"
fi
