#!/bin/bash
set -e -x

# Copies the rpms of a published repo to its new locations and rebuilds and
# signs the repodata for them:
#   <os>/<arch>     -> <os>/<arch>/prime

yum install -y \
  epel-release \
  ca-certificates \
  awscli \
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

case "$OS" in
  "centos8")
    SOURCE_OS="centos/8"
    TARGET_OS="centos/8"
    ;;
  "centos9")
    SOURCE_OS="centos/9"
    TARGET_OS="centos/9"
    ;;
  "centos10")
    SOURCE_OS="centos/10"
    TARGET_OS="centos/10"
    ;;
  "microos")
    SOURCE_OS="microos"
    TARGET_OS="microos"
    ;;
  "slemicro")
    SOURCE_OS="slemicro"
    TARGET_OS="slemicro"
    ;;
  "sle")
    SOURCE_OS="sle"
    TARGET_OS="sle"
    ;;
  *)
    echo "Unsupported OS: $OS, exiting"
    exit 1
    ;;
esac

if [ "$RPM_ARCH" = "all" ]; then
  RPM_ARCHES="x86_64 aarch64 source"
else
  RPM_ARCHES="$RPM_ARCH"
fi

# keys and passphrases must not end up in the xtrace output
set +x
case "$RPM_CHANNEL" in
"testing")
  export PRIVATE_KEY_PASS_PHRASE=$TESTING_PRIVATE_KEY_PASS_PHRASE
  if [[ -n "$TESTING_PRIVATE_KEY" ]] && grep -q "BEGIN PGP PRIVATE KEY BLOCK" <<<"$TESTING_PRIVATE_KEY"; then
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
  if [[ -n "$PRIVATE_KEY" ]] && grep -q "BEGIN PGP PRIVATE KEY BLOCK" <<<"$PRIVATE_KEY"; then
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

if [[ -z "$PRIVATE_KEY_PASS_PHRASE" || ! -f "key.gpg" ]]; then
  echo "missing private key or passphrase, exiting"
  exit 1
fi
set -x

WORK_DIR="./dist"
mkdir -p "$WORK_DIR"

BASE_PATH="s3://$AWS_S3_BUCKET/rke2/$RPM_CHANNEL/$RPM_MAJMIN"

# Uploads in an order that keeps the target repo consistent while it runs:
# rpms first, then repodata files, then repomd.xml and its signature, and
# only at the end the stale repodata files are removed.
upload_repo() {
  local REPO_DIR=$1
  local TARGET_PATH=$2

  echo "uploading $REPO_DIR to $TARGET_PATH"

  aws s3 sync "$REPO_DIR" "$TARGET_PATH" \
    --size-only \
    --exclude "*" \
    --include "*.rpm"

  aws s3 sync "$REPO_DIR/repodata" "$TARGET_PATH/repodata" \
    --exclude "*" \
    --include "*.xml" \
    --include "*.sqlite*" \
    --include "*.gz" \
    --exclude "repomd.xml"

  aws s3 cp "$REPO_DIR/repodata/repomd.xml" "$TARGET_PATH/repodata/repomd.xml"
  aws s3 cp "$REPO_DIR/repodata/repomd.xml.asc" "$TARGET_PATH/repodata/repomd.xml.asc"

  aws s3 sync "$REPO_DIR/repodata" "$TARGET_PATH/repodata" \
    --delete \
    --exclude "*" \
    --include "*.xml" \
    --include "*.xml.asc" \
    --include "*.sqlite*" \
    --include "*.gz"

  echo "Uploaded repo to $TARGET_PATH"
}

copy_arch() {
  local ARCH=$1
  local SOURCE_PATH="$BASE_PATH/$SOURCE_OS/$ARCH"
  local REPO_DIR="$WORK_DIR/$OS-$ARCH"
  local REPODATA_DIR="$REPO_DIR/repodata"
  local REPOMD_FILE="$REPODATA_DIR/repomd.xml"

  echo "downloading rpms from $SOURCE_PATH"
  aws s3 sync "$SOURCE_PATH" "$REPO_DIR" \
    --exclude "*" \
    --include "*.rpm" \
    --exclude "prime/*"

  local RPM_COUNT
  RPM_COUNT=$(find "$REPO_DIR" -name "*.rpm" 2>/dev/null | wc -l)
  if [ "$RPM_COUNT" -eq 0 ]; then
    echo "no rpm files found in $SOURCE_PATH, skipping"
    return
  fi

  echo "Downloaded $RPM_COUNT rpms to $REPO_DIR"

  createrepo_c --checksum sha256 "$REPO_DIR"

  if [ ! -f "$REPOMD_FILE" ]; then
    echo "repomd.xml not created, exiting"
    exit 1
  fi

  echo "signing repomd.xml"
  set +x
  gpg \
    --batch --yes \
    --pinentry-mode loopback \
    --passphrase "$PRIVATE_KEY_PASS_PHRASE" \
    --force-v3-sigs --verbose \
    --detach-sign --armor \
    -u "ci@rancher.com" \
    "$REPOMD_FILE"
  set -x

  if [ "$SKIP_UPLOAD" = "true" ]; then
    echo "skipping s3 upload, repo staged at $REPO_DIR"
    return
  fi

  if [ "$SOURCE_OS" != "$TARGET_OS" ]; then
    upload_repo "$REPO_DIR" "$BASE_PATH/$TARGET_OS/$ARCH"
  fi
  upload_repo "$REPO_DIR" "$BASE_PATH/$TARGET_OS/$ARCH/prime"
}

echo "Working directory: $WORK_DIR"

for ARCH in $RPM_ARCHES; do
  copy_arch "$ARCH"
done
