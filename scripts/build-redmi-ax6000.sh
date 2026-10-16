#!/usr/bin/env bash
set -euo pipefail

REPOSITORY_DIR="${REPOSITORY_DIR:-/workspace}"
BUILD_DIR="${BUILD_DIR:-/build}"
OUTPUT_DIR="${OUTPUT_DIR:-/output}"
JOBS="${JOBS:-4}"
CURL_OPTIONS="${CURL_OPTIONS:---max-time 300 --speed-time 60 --speed-limit 1024}"
LEDE_REPOSITORY="${LEDE_REPOSITORY:-https://github.com/coolsnowwolf/lede.git}"
LEDE_BRANCH="${LEDE_BRANCH:-master}"

export CURL_OPTIONS

SOURCE_DIR="$BUILD_DIR/openwrt"
VERSION_FILE="$BUILD_DIR/versions.txt"

mkdir -p "$BUILD_DIR" "$OUTPUT_DIR"

if [[ -e "$SOURCE_DIR" ]]; then
  echo "构建目录已存在：$SOURCE_DIR" >&2
  echo "请为每次最新源码构建使用新的 BUILD_DIR" >&2
  exit 1
fi

git clone --depth 1 --branch "$LEDE_BRANCH" "$LEDE_REPOSITORY" "$SOURCE_DIR"

{
  echo "LEDE_COMMIT=$(git -C "$SOURCE_DIR" rev-parse HEAD)"
  echo "LEDE_COMMIT_TIME=$(git -C "$SOURCE_DIR" show -s --format=%cI HEAD)"
} > "$VERSION_FILE"

{
  echo 'src-git kenzo https://github.com/kenzok8/openwrt-packages.git'
  echo 'src-git small https://github.com/kenzok8/small.git'
  cat "$SOURCE_DIR/feeds.conf.default"
} > "$SOURCE_DIR/feeds.conf"

cd "$SOURCE_DIR"
./scripts/feeds update -a
"$REPOSITORY_DIR/scripts/prepare-vpn-packages.sh" "$SOURCE_DIR" "$BUILD_DIR/vpn-versions.txt"
./scripts/feeds install -a

{
  echo "KENZO_COMMIT=$(git -C feeds/kenzo rev-parse HEAD)"
  echo "SMALL_COMMIT=$(git -C feeds/small rev-parse HEAD)"
} >> "$VERSION_FILE"
cat "$BUILD_DIR/vpn-versions.txt" >> "$VERSION_FILE"

cp "$REPOSITORY_DIR/redmi_ax6000.config" .config
mkdir -p files
cp -a "$REPOSITORY_DIR/files/." files/
"$REPOSITORY_DIR/scripts/prepare-mihomo-core.sh" "$SOURCE_DIR" "$BUILD_DIR/mihomo-version.txt"
cat "$BUILD_DIR/mihomo-version.txt" >> "$VERSION_FILE"

make defconfig

required_symbols=(
  CONFIG_TARGET_mediatek_filogic_DEVICE_xiaomi_redmi-router-ax6000
  CONFIG_PACKAGE_luci-app-openclash
  CONFIG_PACKAGE_luci-app-passwall
  CONFIG_PACKAGE_luci-app-passwall_Nftables_Transparent_Proxy
  CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Haproxy
  CONFIG_PACKAGE_luci-app-passwall_INCLUDE_ShadowsocksR_Libev_Client
  CONFIG_PACKAGE_luci-app-passwall_INCLUDE_SingBox
  CONFIG_PACKAGE_luci-i18n-passwall-zh-cn
  CONFIG_PACKAGE_luci-theme-argon
  CONFIG_PACKAGE_luci-app-argon-config
  CONFIG_PACKAGE_zerotier
  CONFIG_PACKAGE_luci-app-zerotier
  CONFIG_PACKAGE_luci-i18n-zerotier-zh-cn
  CONFIG_PACKAGE_tailscale
  CONFIG_PACKAGE_luci-app-tailscale-community
  CONFIG_PACKAGE_luci-i18n-tailscale-community-zh-cn
  CONFIG_PACKAGE_socat
  CONFIG_PACKAGE_zram-swap
  CONFIG_PACKAGE_ttyd
  CONFIG_PACKAGE_luci-app-ttyd
  CONFIG_PACKAGE_luci-i18n-ttyd-zh-cn
  CONFIG_PACKAGE_iftop
  CONFIG_PACKAGE_iperf3
  CONFIG_PACKAGE_luci-app-wol
  CONFIG_PACKAGE_luci-i18n-wol-zh-cn
  CONFIG_PACKAGE_luci-app-filetransfer
  CONFIG_PACKAGE_luci-i18n-filetransfer-zh-cn
  CONFIG_PACKAGE_luci-app-arpbind
  CONFIG_PACKAGE_luci-i18n-arpbind-zh-cn
)

for symbol in "${required_symbols[@]}"; do
  if ! grep -qx "${symbol}=y" .config; then
    echo "必需配置未生效：$symbol" >&2
    exit 1
  fi
done

excluded_symbols=(
  CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Geoview
  CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Hysteria
  CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Rust_Client
  CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Simple_Obfs
  CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Plugin
  CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Xray
)

for symbol in "${excluded_symbols[@]}"; do
  if grep -qx "${symbol}=y" .config; then
    echo "精简配置意外启用了：$symbol" >&2
    exit 1
  fi
done

./scripts/diffconfig.sh > "$OUTPUT_DIR/redmi_ax6000.diffconfig"
cp .config "$OUTPUT_DIR/redmi_ax6000.fullconfig"

make download -j"$JOBS"
make -j"$JOBS" V=s

target_dir="$SOURCE_DIR/bin/targets/mediatek/filogic"
sysupgrade_image="$(find "$target_dir" -maxdepth 1 -type f \
  \( -name '*xiaomi_redmi-router-ax6000*squashfs-sysupgrade.bin' \
     -o -name '*xiaomi_redmi-router-ax6000*squashfs-sysupgrade.itb' \) \
  | head -n1)"
if [[ -z "$sysupgrade_image" ]]; then
  echo "没有生成 AX6000 sysupgrade 镜像" >&2
  exit 1
fi

cp "$sysupgrade_image" "$OUTPUT_DIR/"
cp "$target_dir/sha256sums" "$OUTPUT_DIR/target-sha256sums"
cp "$target_dir/profiles.json" "$OUTPUT_DIR/"
find "$target_dir" -maxdepth 1 -type f -name '*xiaomi_redmi-router-ax6000*.manifest' \
  -exec cp {} "$OUTPUT_DIR/" \;
cp "$VERSION_FILE" "$OUTPUT_DIR/versions.txt"

openclash_version="$(sed -n 's/^PKG_VERSION:=//p' feeds/small/luci-app-openclash/Makefile | head -n1)"
passwall_version="$(sed -n 's/^PKG_VERSION:=//p' feeds/small/luci-app-passwall/Makefile | head -n1)"
argon_version="$(sed -n 's/^PKG_VERSION:=//p' feeds/kenzo/luci-theme-argon/Makefile | head -n1)"
{
  echo "OPENCLASH_VERSION=$openclash_version"
  echo "PASSWALL_VERSION=$passwall_version"
  echo "ARGON_VERSION=$argon_version"
} >> "$OUTPUT_DIR/versions.txt"

(
  cd "$OUTPUT_DIR"
  sha256sum "$(basename "$sysupgrade_image")" > SHA256SUMS
)

echo "固件构建完成：$OUTPUT_DIR/$(basename "$sysupgrade_image")"
