#!/usr/bin/env bash
set -euo pipefail

REPOSITORY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="${BUILD_ROOT:-/tmp/autobuild-openwrt-$(date +%Y%m%d-%H%M%S)}"
OUTPUT_DIR="${OUTPUT_DIR:-$REPOSITORY_DIR/output/redmi_ax6000}"
IMAGE_NAME="${IMAGE_NAME:-autobuild-openwrt-builder:latest}"
JOBS="${JOBS:-4}"

mkdir -p "$BUILD_ROOT" "$OUTPUT_DIR"
chmod 0777 "$BUILD_ROOT" "$OUTPUT_DIR"

docker build \
  --tag "$IMAGE_NAME" \
  --file "$REPOSITORY_DIR/docker/openwrt-builder/Dockerfile" \
  "$REPOSITORY_DIR/docker/openwrt-builder"

docker run --rm \
  --user 1000:1000 \
  --env JOBS="$JOBS" \
  --volume "$REPOSITORY_DIR:/workspace:ro" \
  --volume "$BUILD_ROOT:/build" \
  --volume "$OUTPUT_DIR:/output" \
  "$IMAGE_NAME" \
  /workspace/scripts/build-redmi-ax6000.sh
