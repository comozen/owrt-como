#
# owrt-como - 个人自定义文件包
#
# 作用：把 files/ 目录里的内容原样安装进固件 rootfs。
# 不编译任何源码，纯文件包；所有内容都随固件一起分发，
# 因此 sysupgrade 升级后天然存在，不需要手动补。
#

include $(TOPDIR)/rules.mk

PKG_NAME:=owrt-como
PKG_VERSION:=1.0
PKG_RELEASE:=1
PKG_LICENSE:=MIT
PKG_MAINTAINER:=Como <virzen@me.com>

include $(INCLUDE_DIR)/package.mk

define Package/owrt-como
  SECTION:=base
  CATEGORY:=Base system
  TITLE:=Como personal custom files
  PKGARCH:=all
endef

define Package/owrt-como/description
  Personal custom files for the firmware:
  apk signing keys, extra package repositories, uci-defaults, etc.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Compile
endef

define Package/owrt-como/install
	$(INSTALL_DIR) $(1)
	$(CP) $(CURDIR)/files/. $(1)/
endef

$(eval $(call BuildPackage,owrt-como))
