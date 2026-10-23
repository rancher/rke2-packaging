#!/bin/bash
# Source this file; never infer an OS from the host running the uploader.
case "${RPM_OS:-}" in
  centos8 | centos9 | centos10)
    RPM_SPEC_OS=$RPM_OS
    RPM_REPO_OS="centos/${RPM_OS#centos}"
    RPM_DIST=
    RPM_SPECTOOL=spectool
    ;;
  microos | slemicro)
    RPM_SPEC_OS=$RPM_OS
    RPM_REPO_OS=$RPM_OS
    RPM_DIST=.sle
    if [[ "$RPM_OS" == slemicro ]]; then RPM_DIST=.slemicro; fi
    RPM_SPECTOOL=rpmdev-spectool
    ;;
  *)
    echo "RPM_OS must be centos8, centos9, centos10, microos, or slemicro, got: ${RPM_OS:-<unset>}" >&2
    return 1
    ;;
esac
export RPM_OS
SOURCE=${SOURCE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}
SOURCE=$(cd "$SOURCE" && pwd) || return 1

rpm_architecture() {
  if [[ ! "${COMBARCH:-}" =~ ^([a-zA-Z0-9_]+)-([a-zA-Z0-9_]+)$ ]]; then
    echo "Combined architecture must be <rpmarch>-<goarch>, got: ${COMBARCH:-<unset>}" >&2
    return 1
  fi
  RPMARCH=${BASH_REMATCH[1]}
  GOARCH=${BASH_REMATCH[2]}
}