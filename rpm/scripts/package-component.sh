#!/bin/bash
set -euo pipefail
SCRIPTS=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPTS/config.sh"
rpm_architecture
component=${1:-}
case "$component" in
  common | server | agent) ;;
  *) echo "Invalid RPM component: $component" >&2; exit 1 ;;
esac
case "${RPM_REPOSITORY:-community}" in
  community) RKE2_ASSET_BASE=https://github.com/rancher/rke2/releases/download ;;
  prime) RKE2_ASSET_BASE=https://prime.ribs.rancher.io/rke2 ;;
  *) echo "RPM_REPOSITORY must be community or prime, got: $RPM_REPOSITORY" >&2; exit 1 ;;
esac
. "$SCRIPTS/version.sh"

# Overrideable for local/offline testing; production retains the original topdir.
RPM_TOPDIR=${RPM_TOPDIR:-/root/rpmbuild}
SRC_PATH="$RPM_TOPDIR/SOURCES/$RPMARCH"
SPEC_PATH="$SOURCE/rpm/$RPM_SPEC_OS/$component"
SPEC="rke2-$component.spec"
mkdir -p "$RPM_TOPDIR/SPECS" "$SRC_PATH"
cp -r "$SPEC_PATH/"* "$SRC_PATH/"
CHANGELOG_PATH="$SRC_PATH/CHANGELOG.md"
. "$SCRIPTS/gen-changelog.sh" "$CHANGELOG_PATH"
sed -i "s/\%global ARCH.*/\%global ARCH ${GOARCH}/" "$SRC_PATH/$SPEC"
sed -i "s|https://github.com/rancher/rke2/releases/download/|$RKE2_ASSET_BASE/|" "$SRC_PATH/$SPEC"
if [[ "${RPM_REPOSITORY:-community}" == prime ]]; then
  # Prime only serves the version path URL encoded (+ -> %2B), %% keeps rpm
  # from expanding it as a macro.
  sed -i "s|$RKE2_ASSET_BASE/%{rke2_version}/|$RKE2_ASSET_BASE/${RKE2_VERSION//+/%%2B}/|" "$SRC_PATH/$SPEC"
fi
cp "$SRC_PATH/$SPEC" "$RPM_TOPDIR/SPECS/"

cd "$SRC_PATH"
dist_args=()
if [[ -n "$RPM_DIST" ]]; then dist_args=(--define "dist $RPM_DIST"); fi
"$RPM_SPECTOOL" -gf "$SPEC" \
  --define "_topdir $RPM_TOPDIR" \
  --define "rke2_version $RKE2_VERSION" \
  --define "changelog_path $CHANGELOG_PATH" \
  --define "ARCH $GOARCH"
rpmbuild -vv \
  --define "_topdir $RPM_TOPDIR" \
  --define "rpm_version $RPM_VERSION" \
  --define "rke2_version $RKE2_VERSION" \
  --define "rpm_release $RPM_RELEASE" \
  --define "rke2_policyver $RKE2_POLICYVER" \
  --define "changelog_path $CHANGELOG_PATH" \
  --define "_sourcedir $SRC_PATH" \
  "${dist_args[@]}" --target "$RPMARCH" -ba "$SRC_PATH/$SPEC"

mkdir -p "$SOURCE/dist/$RPM_OS/source"
cp -r "$RPM_TOPDIR/RPMS/"* "$SOURCE/dist/$RPM_OS/"
cp -r "$RPM_TOPDIR/SRPMS/"* "$SOURCE/dist/$RPM_OS/source/"
cp "$CHANGELOG_PATH" "$SOURCE/dist/$RPM_OS/CHANGELOG_${component^^}.md"