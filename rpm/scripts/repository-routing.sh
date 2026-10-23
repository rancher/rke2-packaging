#!/bin/bash
# Sourced by every sign-and-upload script before any external operations.
# community packages are built from the GitHub release assets and published to
# <os>/<arch>, prime packages are built from the Prime assets and published to
# <os>/<arch>/prime. They are different binaries, so each one only goes to its
# own repository.
RPM_REPOSITORY=${RPM_REPOSITORY:-community}
case "$RPM_REPOSITORY" in
  community) RPM_REPOSITORY_SUFFIX= ;;
  prime) RPM_REPOSITORY_SUFFIX=/prime ;;
  *)
    echo "RPM_REPOSITORY must be community or prime, got: $RPM_REPOSITORY" >&2
    return 1
    ;;
esac

upload_rpm_repositories() {
  rpm_tooling --bucket "$AWS_S3_BUCKET/$TARGET_S3_PATH$RPM_REPOSITORY_SUFFIX" --sign \
    --sign-pass "$PRIVATE_KEY_PASS_PHRASE" \
    --aws-access-key "$AWS_ACCESS_KEY_ID" --aws-secret-key "$AWS_SECRET_ACCESS_KEY" \
    $TARGET_RPM_PATH
}
