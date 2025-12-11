#!/bin/bash
#=================================================
# Description: DIY script
# Lisence: MIT
# Author: eSirPlayground
# Youtube Channel: https://goo.gl/fvkdwm
#=================================================

# ---------- 1. 修改默认 IP ----------
CFG_GEN_OLD="openwrt/package/base-files/files/bin/config_generate"
if [ -f "$CFG_GEN_OLD" ]; then
  sed -i 's/192\.168\.1\.1/192\.168\.5\.1/g' "$CFG_GEN_OLD"
fi

# ---------- 2. 清空登录密码（按需开启） ----------
# ZZZ_CFG="openwrt/package/lean/default-settings/files/zzz-default-settings"
# if [ -f "$ZZZ_CFG" ]; then
#   sed -i 's/$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.//g' "$ZZZ_CFG"
# fi

# ---------- 3. 替换 Argon 主题（按需开启） ----------
# rm -rf openwrt/package/lean/luci-theme-argon

# ---------- 4. 23.05 相关 UI 文本修改 ----------
FLASH_JS="openwrt/feeds/luci/modules/luci-mod-system/htdocs/luci-static/resources/view/system/flash.js"
if [ -f "$FLASH_JS" ]; then
  sed -i 's/192\.168\.1\.1/192\.168\.55\.1/g' "$FLASH_JS"
fi

CFG_GEN_LUCI2="openwrt/package/base-files/luci2/bin/config_generate"
if [ -f "$CFG_GEN_LUCI2" ]; then
  sed -i 's/192\.168\.1\.1/192\.168\.55\.1/g' "$CFG_GEN_LUCI2"
  sed -i 's/LEDE/OpenWrt/g' "$CFG_GEN_LUCI2"
fi

MAC80211_SH="openwrt/package/kernel/mac80211/files/lib/wifi/mac80211.sh"
if [ -f "$MAC80211_SH" ]; then
  sed -i 's/LEDE/OpenWrt/g' "$MAC80211_SH"
fi
