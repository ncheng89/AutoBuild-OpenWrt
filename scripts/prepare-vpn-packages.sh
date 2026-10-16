#!/usr/bin/env bash
set -euo pipefail

OPENWRT_DIR="${1:?缺少 OpenWrt 源码目录}"
METADATA_FILE="${2:?缺少版本记录文件}"

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

update_package() {
  local package="$1"
  local repository="$2"
  local tag_prefix="$3"
  local makefile="$OPENWRT_DIR/feeds/packages/net/$package/Makefile"
  local release_json="$work_dir/$package-release.json"
  local archive="$work_dir/$package.tar.gz"
  local tag version source_url source_sha256

  curl --fail --location --silent --show-error \
    --retry 5 --retry-all-errors \
    "https://api.github.com/repos/$repository/releases/latest" \
    -o "$release_json"

  tag="$(jq -r '.tag_name' "$release_json")"
  version="${tag#${tag_prefix}}"
  if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "$package 的最新版本号格式无效：$tag" >&2
    exit 1
  fi

  source_url="https://codeload.github.com/$repository/tar.gz/$tag"
  curl --fail --location --silent --show-error \
    --retry 5 --retry-all-errors \
    "$source_url" -o "$archive"
  source_sha256="$(sha256sum "$archive" | awk '{print $1}')"

  sed -i -E \
    -e "s/^PKG_VERSION:=.*/PKG_VERSION:=$version/" \
    -e "s/^PKG_HASH:=.*/PKG_HASH:=$source_sha256/" \
    "$makefile"

  {
    echo "${package^^}_VERSION=$version"
    echo "${package^^}_SOURCE_SHA256=$source_sha256"
  } >> "$METADATA_FILE"
}

fix_tcping_cross_strip() {
  local makefile="$OPENWRT_DIR/feeds/small/tcping/Makefile"

  [[ -f "$makefile" ]] || return 0
  if ! grep -Fq 'STRIP="$(TARGET_CROSS)strip"' "$makefile"; then
    sed -i \
      's|LDFLAGS="$(TARGET_LDFLAGS)"|LDFLAGS="$(TARGET_LDFLAGS)" STRIP="$(TARGET_CROSS)strip"|' \
      "$makefile"
  fi

  if ! grep -Fq 'STRIP="$(TARGET_CROSS)strip"' "$makefile"; then
    echo "tcping 未能切换到目标架构 strip" >&2
    exit 1
  fi
}

: > "$METADATA_FILE"
update_package zerotier zerotier/ZeroTierOne ""
update_package tailscale tailscale/tailscale "v"
fix_tcping_cross_strip
