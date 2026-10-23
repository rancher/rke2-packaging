#!/bin/bash
# May be sourced from any directory. Do not change the caller's cwd or options.
rpm_version() {
  local git_commit rate upstream packaging_version
  RKE2_POLICYVER=0.12-0
  RKE2_FALLBACKVER=${RKE2_FALLBACKVER:-v1.22.6+rke2r1}
  SOURCE=${SOURCE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}
  COMMIT=${COMMIT:-${DRONE_COMMIT:-${GITHUB_SHA:-}}}
  TAG=${TAG:-${DRONE_TAG:-${GITHUB_TAG:-}}}
  if [[ -z "$TAG" && "${GITHUB_REF_TYPE:-}" == tag ]]; then
    TAG=${GITHUB_REF_NAME:-}
  fi
  TREE_STATE=clean
  DIRTY=
  # Command-scoped safe.directory avoids modifying the user's global Git config.
  if [[ -n "$(git -c "safe.directory=$SOURCE" -C "$SOURCE" status --porcelain --untracked-files=no)" ]]; then
    TREE_STATE=dirty
    DIRTY=dirty
  fi
  if git_commit=$(git -c "safe.directory=$SOURCE" -C "$SOURCE" rev-parse HEAD); then
    COMMIT=$git_commit
  fi
  if [[ -z "$COMMIT" || "$COMMIT" == unknown ]]; then
    echo 'Unknown commit hash. Exiting.' >&2
    return 1
  fi
  if [[ "$TREE_STATE" == clean && -z "$TAG" ]]; then
    # Keep the historical first-containing-tag behavior without a SIGPIPE pipeline.
    TAG=$(git -c "safe.directory=$SOURCE" -C "$SOURCE" tag -l --contains HEAD)
    TAG=${TAG%%$'\n'*}
  fi
  VERSION=
  if [[ "$TREE_STATE" == clean && -n "$TAG" ]]; then
    if [[ ! "$TAG" =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)([-+][a-zA-Z0-9.]+)?[-+](rke2r[0-9]+|dev.*)\.(testing|latest|stable)\.[0-9]+$ ]]; then
      echo 'Tag does not match our expected format. Exiting.' >&2
      return 1
    fi
    VERSION=$TAG
    RPM_RELEASE=${TAG##*.}
    packaging_version=${TAG%.*}
    RPM_CHANNEL=${packaging_version##*.}
    RKE2_VERSION=${packaging_version%.*}
    packaging_version=$RKE2_VERSION
  else
    # Untagged/dirty builds retain the GitHub lookup and a known-good fallback.
    upstream=$RKE2_FALLBACKVER
    rate=$(curl -fsSL https://api.github.com/rate_limit | jq -r '.rate.remaining' ) || rate=
    if [[ -n "$rate" && "$rate" != 0 && "$rate" != null ]]; then
      upstream=$(curl -fsSL https://api.github.com/repos/rancher/rke2/releases |
        jq -r '[.[] | select((.assets | length) > 2)][0].tag_name') || upstream=
    fi
    if [[ ! "$upstream" =~ ^v[0-9]+\.[0-9]+\.[0-9]+.*\+rke2r[0-9]+$ ]]; then
      upstream=$RKE2_FALLBACKVER
    fi
    RKE2_VERSION=$upstream
    VERSION=$(sed -E "s/(\+rke2r[0-9]+)/-${COMMIT:0:8}${DIRTY}\\1/" <<< "$upstream")
    packaging_version=$VERSION
    RPM_RELEASE=0
    RPM_CHANNEL=testing
  fi
  RPM_VERSION=${packaging_version#v}
  RPM_VERSION=${RPM_VERSION//-/\~}
  RPM_VERSION=${RPM_VERSION//+/\~}
  if [[ ! "$VERSION" =~ ^v([0-9]+)\.([0-9]+)\. ]]; then
    echo "Unknown RPM_MAJMIN found: $VERSION" >&2
    return 1
  fi
  RPM_MAJMIN=${BASH_REMATCH[1]}.${BASH_REMATCH[2]}
}
rpm_version