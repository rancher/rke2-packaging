#!/bin/bash
set -euo pipefail
SCRIPTS=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPTS/config.sh"
case "${1:-}" in
  build | build-common | build-server | build-agent | sign-and-upload | version)
    script=$1
    shift
    bash "$SCRIPTS/$script.sh" "$@"
    # Preserve the CentOS 9 Dapper ownership handoff with safe unset defaults.
    if [[ "$RPM_OS" == centos9 && "${DAPPER_UID:--1}" != -1 ]]; then
      chown -R "${DAPPER_UID}:${DAPPER_GID:?DAPPER_GID is required}" "$SOURCE"
    fi
    ;;
  '') echo 'A script or command is required' >&2; exit 1 ;;
  *) exec "$@" ;;
esac