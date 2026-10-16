#!/usr/bin/env bash
set -euo pipefail

OPENWRT_DIR="${1:?缺少 OpenWrt 源码目录}"
METADATA_FILE="${2:?缺少版本记录文件}"

ZEROTIER_LUCI_REPOSITORY="${ZEROTIER_LUCI_REPOSITORY:-https://github.com/rabbitrogi/luci-app-zerotier.git}"
ZEROTIER_LUCI_COMMIT="${ZEROTIER_LUCI_COMMIT:-d4c4e1167b51101ad9a6f77856027d0b27cb0b5b}"

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

git -C "$work_dir" init -q
git -C "$work_dir" remote add origin "$ZEROTIER_LUCI_REPOSITORY"
git -C "$work_dir" fetch --depth 1 origin "$ZEROTIER_LUCI_COMMIT"

resolved_commit="$(git -C "$work_dir" rev-parse FETCH_HEAD)"
if [[ "$resolved_commit" != "$ZEROTIER_LUCI_COMMIT" ]]; then
  echo "ZeroTier LuCI 提交不匹配：$resolved_commit" >&2
  exit 1
fi

package_dir="$work_dir/package"
mkdir -p "$package_dir"
git -C "$work_dir" archive FETCH_HEAD | tar -x -C "$package_dir"

version="$(sed -n 's/^PKG_VERSION:=//p' "$package_dir/Makefile")"
release="$(sed -n 's/^PKG_RELEASE:=//p' "$package_dir/Makefile")"
if [[ "$version" != "2.2" || "$release" != "49" ]]; then
  echo "ZeroTier LuCI 版本不符合固定版本：${version}-r${release}" >&2
  exit 1
fi

init_script="$package_dir/root/etc/init.d/luci-zerotier"
for required_rule in \
  "set firewall.zerotier=zone" \
  "set firewall.zerotier_lan=forwarding" \
  "set firewall.lan_zerotier=forwarding"; do
  if ! grep -Fq "$required_rule" "$init_script"; then
    echo "ZeroTier LuCI 缺少防火墙规则：$required_rule" >&2
    exit 1
  fi
done

target_dir="$OPENWRT_DIR/package/luci-app-zerotier"
rm -rf "$OPENWRT_DIR/package/feeds/luci/luci-app-zerotier" "$target_dir"
mkdir -p "$target_dir"
cp -a "$package_dir/." "$target_dir/"

{
  echo "ZEROTIER_LUCI_VERSION=${version}-r${release}"
  echo "ZEROTIER_LUCI_COMMIT=$resolved_commit"
} > "$METADATA_FILE"
