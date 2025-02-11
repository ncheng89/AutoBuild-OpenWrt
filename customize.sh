#!/bin/bash
#=================================================
# Description: DIY script
# Lisence: MIT
# Author: eSirPlayground
# Youtube Channel: https://goo.gl/fvkdwm 
#=================================================
#1. Modify default IP
sed -i 's/192.168.1.1/192.168.5.1/g' openwrt/package/base-files/files/bin/config_generate

#2. Clear the login password
#sed -i 's/$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.//g' openwrt/package/lean/default-settings/files/zzz-default-settings

#3. Replace with JerryKuKu’s Argon
#rm openwrt/package/lean/luci-theme-argon -rf

#23.05主题修改
sed -i 's/192\.168\.1\.1/192\.168\.55\.1/g' openwrt/feeds/luci/modules/luci-mod-system/htdocs/luci-static/resources/view/system/flash.js
sed -i 's/192\.168\.1\.1/192\.168\.55\.1/g' openwrt/package/base-files/luci2/bin/config_generate
sed -i 's/LEDE/OpenWrt/g' openwrt/package/base-files/luci2/bin/config_generate
sed -i 's/LEDE/OpenWrt/g' openwrt/package/kernel/mac80211/files/lib/wifi/mac80211.sh
