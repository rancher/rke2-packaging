#!/bin/bash
set -e -x

yum install -y \
  epel-release \
  ca-certificates \
  awscli \
  yum-utils \
  createrepo_c \
  sqlite \
  gpg \
  pinentry

if [ -z "$RPM_ARCH" ]; then
  echo "RPM_ARCH was not defined, exiting"
  exit 1
fi

if [ -z "$RPM_MAJMIN" ]; then
  echo "RPM_MAJMIN not defined, exiting"
  exit 1
fi

if [ -z "$RPM_CHANNEL" ]; then
  echo "RPM_CHANNEL not defined, exiting"
  exit 1
fi

if [ -z "$OS" ]; then
  echo "OS not defined, exiting"
  exit 1
fi

# Validate OS and set up base URL path
case "$OS" in
  "centos7")
    BASEURL_OS="centos/7"
    ;;
  "centos8")
    BASEURL_OS="centos/8"
    ;;
  "centos9")
    BASEURL_OS="centos/9"
    ;;
  "microos")
    BASEURL_OS="microos"
    ;;
  "slemicro")
    BASEURL_OS="slemicro"
    ;;
  *)
    echo "Unsupported OS: $OS, exiting"
    exit 1
    ;;
esac



RKE2_REPO_VERSION=$(echo "$RPM_MAJMIN" | tr '.' '-')
REPO_ID="rancher-rke2-${RKE2_REPO_VERSION}-${RPM_CHANNEL}"

REPO_DOMAIN=${RKE2_REPO_DOMAIN:-"rpm.rancher.io"}
if [ "${RPM_CHANNEL}" = "testing" ]; then
  REPO_DOMAIN="rpm-testing.rancher.io"
fi

REPO_BASEURL="https://${REPO_DOMAIN}/rke2/${RPM_CHANNEL}/${RPM_MAJMIN}/${BASEURL_OS}/${RPM_ARCH}"
TARGET_S3_PATH="rke2/$RPM_CHANNEL/$RPM_MAJMIN/$BASEURL_OS/$RPM_ARCH"

cat << EOF > /etc/yum.repos.d/${REPO_ID}.repo
[${REPO_ID}]
name=Rancher RKE2 ${RPM_MAJMIN} ${RPM_CHANNEL}
baseurl=${REPO_BASEURL}
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://${REPO_DOMAIN}/public.key
EOF

case "$RPM_CHANNEL" in
"testing")
  export PRIVATE_KEY_PASS_PHRASE=$TESTING_PRIVATE_KEY_PASS_PHRASE
  if [[ -n "$TESTING_PRIVATE_KEY" ]] && grep "BEGIN PGP PRIVATE KEY BLOCK" <<<"$TESTING_PRIVATE_KEY"; then
    echo "$TESTING_PRIVATE_KEY" >key.gpg
    gpg --batch --passphrase "$PRIVATE_KEY_PASS_PHRASE" --import key.gpg
  else
    echo "TESTING_PRIVATE_KEY not defined, skipping rpm signing"
  fi
  if [ -z "$TESTING_AWS_S3_BUCKET" ]; then
    echo "TESTING_AWS_S3_BUCKET not defined, exiting"
    exit 1
  fi
  if [ -z "$TESTING_AWS_ACCESS_KEY_ID" ]; then
    echo "TESTING_AWS_ACCESS_KEY_ID not defined, exiting"
    exit 1
  fi
  if [ -z "$TESTING_AWS_SECRET_ACCESS_KEY" ]; then
    echo "TESTING_AWS_SECRET_ACCESS_KEY not defined, exiting"
    exit 1
  fi
  export AWS_ACCESS_KEY_ID=$TESTING_AWS_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY=$TESTING_AWS_SECRET_ACCESS_KEY
  export AWS_S3_BUCKET=$TESTING_AWS_S3_BUCKET
  ;;

"latest" | "stable")
  if [[ -n "$PRIVATE_KEY" ]] && grep "BEGIN PGP PRIVATE KEY BLOCK" <<<"$PRIVATE_KEY"; then
    echo "$PRIVATE_KEY" >key.gpg
    gpg --batch --passphrase "$PRIVATE_KEY_PASS_PHRASE" --import key.gpg
  else
    echo "PRIVATE_KEY not defined, skipping rpm signing"
  fi
  if [ -z "$AWS_S3_BUCKET" ]; then
    echo "AWS_S3_BUCKET not defined, exiting"
    exit 1
  fi
  if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo "AWS_ACCESS_KEY_ID not defined, exiting"
    exit 1
  fi
  if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "AWS_SECRET_ACCESS_KEY not defined, exiting"
    exit 1
  fi
  ;;
*)
  echo "RPM_CHANNEL $RPM_CHANNEL does not match one of: [testing, latest, stable]"
  exit 1
  ;;
esac

WORK_DIR="./dist"
mkdir -p "$WORK_DIR"

echo "Working directory: $WORK_DIR"
echo "Repository ID: $REPO_ID"
echo "Repo baseurl: $REPO_BASEURL"
echo "Target S3 Path: s3://$AWS_S3_BUCKET/$TARGET_S3_PATH"

if ! reposync \
  --repoid "$REPO_ID" \
  --download-path "$WORK_DIR" \
  -y; then
  echo "reposync exited with non-zero code, continuing with available RPMs"
fi

REPO_DIR="$WORK_DIR/$REPO_ID"
if [ ! -d "$REPO_DIR" ]; then
  echo "$REPO_DIR was not created, exiting"
  exit 1
fi

RPM_COUNT=$(find "$REPO_DIR" -name "*.rpm" | wc -l)
if [ "$RPM_COUNT" -eq 0 ]; then
  echo "no rpm files found in $REPO_DIR, exiting"
  exit 1
fi

echo "Downloaded $RPM_COUNT rpms to $REPO_DIR"

createrepo_c --checksum sha256 "$REPO_DIR"

REPODATA_DIR="$REPO_DIR/repodata"
REPOMD_FILE="$REPODATA_DIR/repomd.xml"

if [ ! -d "$REPODATA_DIR" ]; then
  echo "repodata directory not created, exiting"
  exit 1
fi

if [ ! -f "$REPOMD_FILE" ]; then
  echo "repomd.xml not created, exiting"
  exit 1
fi

if [[ -z "$PRIVATE_KEY_PASS_PHRASE" || ! -f "key.gpg" ]]; then
  echo "missing private key or passphrase, exiting"
  exit 1
fi

echo "signing repomd.xml"
gpg \
  --batch --yes \
  --pinentry-mode loopback \
  --passphrase "$PRIVATE_KEY_PASS_PHRASE" \
  --force-v3-sigs --verbose \
  --detach-sign --armor \
  -u "ci@rancher.com" \
  "$REPOMD_FILE"

if [ "$SKIP_UPLOAD" = "true" ]; then
  echo "skipping s3 upload, repodata staged at $REPODATA_DIR"
  exit 0
fi

echo "uploading repodata to bucket"
aws s3 sync "$REPODATA_DIR" "s3://$AWS_S3_BUCKET/$TARGET_S3_PATH/repodata" \
  --delete \
  --exclude "*" \
  --include "*.xml" \
  --include "*.xml.asc" \
  --include "*.sqlite*" \
  --include "*.gz"

echo "Uploaded repodata to s3://$AWS_S3_BUCKET/$TARGET_S3_PATH/repodata"
