#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${MORSS_FLUTTER_ROOT:-}" ]]; then
  morss_flutter="${MORSS_FLUTTER_ROOT}/bin/flutter"
elif command -v flutter >/dev/null 2>&1; then
  morss_flutter="$(command -v flutter)"
else
  morss_flutter="${HOME}/.local/share/morss-tooling/flutter/bin/flutter"
fi

if [[ ! -f "$morss_flutter" ]]; then
  printf '%s\n' 'Install Flutter, or set MORSS_FLUTTER_ROOT to the SDK directory.' >&2
  exit 1
fi

if [[ "${PREFIX:-}" == /data/data/com.termux/files/usr ]]; then
  exec env -u LD_PRELOAD -u LD_LIBRARY_PATH LC_ALL=C bash "$morss_flutter" "$@"
fi
exec bash "$morss_flutter" "$@"
