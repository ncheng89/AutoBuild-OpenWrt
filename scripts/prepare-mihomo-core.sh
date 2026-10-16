#!/usr/bin/env bash
set -euo pipefail

OPENWRT_DIR="${1:?缺少 OpenWrt 源码目录}"
METADATA_FILE="${2:?缺少版本记录文件}"
API_URL="https://api.github.com/repos/MetaCubeX/mihomo/releases/tags/Prerelease-Alpha"

release_json="$(mktemp)"
archive="$(mktemp --suffix=.gz)"
trap 'rm -f "$release_json" "$archive"' EXIT

curl --fail --location --silent --show-error \
  --retry 5 --retry-all-errors \
  "$API_URL" -o "$release_json"

asset_name="$(jq -r '.assets[] | select(.name | test("^mihomo-linux-arm64-alpha-[^.]+\\.gz$")) | .name' "$release_json" | head -n1)"
asset_url="$(jq -r --arg name "$asset_name" '.assets[] | select(.name == $name) | .browser_download_url' "$release_json")"
asset_digest="$(jq -r --arg name "$asset_name" '.assets[] | select(.name == $name) | .digest' "$release_json")"
asset_updated="$(jq -r --arg name "$asset_name" '.assets[] | select(.name == $name) | .updated_at' "$release_json")"

if [[ -z "$asset_name" || "$asset_url" == "null" || ! "$asset_digest" =~ ^sha256:[0-9a-f]{64}$ ]]; then
  echo "没有找到带 SHA256 摘要的 Mihomo ARM64 Alpha 核心" >&2
  exit 1
fi

curl --fail --location --silent --show-error \
  --retry 5 --retry-all-errors \
  "$asset_url" -o "$archive"

expected_sha256="${asset_digest#sha256:}"
actual_sha256="$(sha256sum "$archive" | awk '{print $1}')"
if [[ "$actual_sha256" != "$expected_sha256" ]]; then
  echo "Mihomo 核心摘要校验失败" >&2
  exit 1
fi

install -d "$OPENWRT_DIR/files/etc/openclash/core"
gzip -dc "$archive" > "$OPENWRT_DIR/files/etc/openclash/core/clash_meta"
chmod 0755 "$OPENWRT_DIR/files/etc/openclash/core/clash_meta"

cat > "$METADATA_FILE" <<EOF
MIHOMO_ASSET=$asset_name
MIHOMO_UPDATED_AT=$asset_updated
MIHOMO_SHA256=$actual_sha256
EOF
