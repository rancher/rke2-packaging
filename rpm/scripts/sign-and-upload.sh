#!/bin/bash
set -euo pipefail
SCRIPTS=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPTS/config.sh"
rpm_architecture

# The upload container is CentOS for every target OS, not the build image.
dnf install -y epel-release wget
dnf install -y python3 python3-pip python3-devel rpm-sign expect git
dnf install -y ca-certificates createrepo_c pinentry pinentry-curses
pip install --upgrade boto3 pexpect
. "$SCRIPTS/version.sh"

# Artifacts are relative to the invocation directory, as in the legacy uploaders.
# Version resolution uses SOURCE without moving the caller away from dist/.
if [[ "${UPLOAD_ARCH:-}" == srcrpm ]]; then RPMARCH=source; fi
TARGET_S3_PATH="rke2/$RPM_CHANNEL/$RPM_MAJMIN/$RPM_REPO_OS/$RPMARCH"
TARGET_RPM_PATH="dist/$RPM_OS/$RPMARCH/rke2-*.rpm"
if [[ "$RPMARCH" == source ]]; then
  TARGET_RPM_PATH="dist/$RPM_OS/source/rke2-*.src.rpm"
fi

cat <<\EOF >~/.rpmmacros
%_signature gpg
%_gpg_name ci@rancher.com
%__gpg_sign_cmd %{__gpg} gpg --pinentry-mode loopback --force-v3-sigs --verbose --no-armor -u "%{_gpg_name}" -sbo %{__signature_filename} --digest-algo sha256 %{__plaintext_filename}
%_source_filedigest_algorithm 8
%_binary_filedigest_algorithm 8
EOF

if [[ "$RPM_CHANNEL" == testing ]]; then
  PRIVATE_KEY=${TESTING_PRIVATE_KEY:-}
  PRIVATE_KEY_PASS_PHRASE=${TESTING_PRIVATE_KEY_PASS_PHRASE:-}
  AWS_S3_BUCKET=${TESTING_AWS_S3_BUCKET:-}
  AWS_ACCESS_KEY_ID=${TESTING_AWS_ACCESS_KEY_ID:-}
  AWS_SECRET_ACCESS_KEY=${TESTING_AWS_SECRET_ACCESS_KEY:-}
fi
if [[ "${PRIVATE_KEY:-}" != *'BEGIN PGP PRIVATE KEY BLOCK'* ]]; then
  echo "Private key not defined for $RPM_CHANNEL, failing rpm sign" >&2
  exit 1
fi
for required in AWS_S3_BUCKET AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY; do
  if [[ -z "${!required:-}" ]]; then
    echo "$required not defined for $RPM_CHANNEL, failing rpm upload" >&2
    exit 1
  fi
done
PRIVATE_KEY_PASS_PHRASE=${PRIVATE_KEY_PASS_PHRASE:-}
export PRIVATE_KEY_PASS_PHRASE AWS_S3_BUCKET AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
printf '%s\n' "$PRIVATE_KEY" >key.gpg
gpg --batch --passphrase "$PRIVATE_KEY_PASS_PHRASE" --import key.gpg

RPM_TOOLING_SHA256=fa468d7a4459eff0ae9924286f2a4faf50d101f110798ca675033f0156118c85
wget -q https://raw.githubusercontent.com/rancher/ecm-distro-tools/master/bin/rpm_tooling -O rpm_tooling
echo "${RPM_TOOLING_SHA256}  rpm_tooling" | sha256sum -c -
chmod +x rpm_tooling
mv ./rpm_tooling /usr/bin
rpm_tooling --bucket "$AWS_S3_BUCKET/$TARGET_S3_PATH" --sign \
  --sign-pass "$PRIVATE_KEY_PASS_PHRASE" \
  --aws-access-key "$AWS_ACCESS_KEY_ID" --aws-secret-key "$AWS_SECRET_ACCESS_KEY" \
  $TARGET_RPM_PATH