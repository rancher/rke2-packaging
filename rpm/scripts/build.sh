#!/bin/bash
set -euo pipefail
SCRIPTS=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPTS/config.sh"
rpm_architecture
for component in common server agent; do
  bash "$SCRIPTS/build-$component.sh"
done