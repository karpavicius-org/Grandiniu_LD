#!/bin/sh
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ARCHIVE=${1:-"$HERE/Grandiniu_LD_pilnas_paketas_licencija_EN_LT_2026-10-22.zip"}
exec ssh-keygen -Y verify -f "$HERE/allowed_signers" \
  -I grandiniu-ld-release-20261022 -n grandiniu-ld-release \
  -s "$HERE/Grandiniu_LD_pilnas_paketas_licencija_EN_LT_2026-10-22.zip.sig" < "$ARCHIVE"
