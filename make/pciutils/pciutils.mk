$(call PKG_INIT_BIN,3.1.7)
$(PKG)_SOURCE:=$(pkg)-$($(PKG)_VERSION).tar.bz2
$(PKG)_SOURCE_MD5:=35222edb86b50a6641352c66fe829b2e
$(PKG)_SITE:=@KERNEL/software/utils/$(pkg)

$(PKG)_BINARY:=$($(PKG)_DIR)/lspci
$(PKG)_SETPCI_BINARY:=$($(PKG)_DIR)/setpci
$(PKG)_IDS:=$($(PKG)_DIR)/pci.ids
$(PKG)_TARGET_BINARY:=$($(PKG)_DEST_DIR)/usr/bin/lspci
$(PKG)_SETPCI_TARGET_BINARY:=$($(PKG)_DEST_DIR)/usr/bin/setpci
$(PKG)_TARGET_IDS:=$($(PKG)_DEST_DIR)/usr/share/pci.ids

$(PKG_SOURCE_DOWNLOAD)
$(PKG_UNPACKED)
$(PKG_CONFIGURED_NOP)

$($(PKG)_BINARY) $($(PKG)_SETPCI_BINARY): $($(PKG)_DIR)/.configured
	$(SUBMAKE) -C $(PCIUTILS_DIR) \
		CC=$(TARGET_CC) \
		CFLAGS="$(TARGET_CFLAGS)" \
		IDSDIR="/usr/share" \
		HOST="$(GNU_TARGET_NAME)" \
		ZLIB="no"

$($(PKG)_TARGET_BINARY): $($(PKG)_BINARY)
	$(INSTALL_BINARY_STRIP)

$($(PKG)_SETPCI_TARGET_BINARY): $($(PKG)_SETPCI_BINARY)
	$(INSTALL_BINARY_STRIP)

$($(PKG)_TARGET_IDS): $($(PKG)_IDS)
	(cd $(PCIUTILS_DIR); ./update-pciids.sh)
	$(INSTALL_FILE)

$(pkg):

ifeq ($(strip $(FREETZ_PACKAGE_$(PKG)_IDS)),y)
$(pkg)-precompiled: $($(PKG)_TARGET_BINARY) $($(PKG)_SETPCI_TARGET_BINARY) \
		$($(PKG)_TARGET_IDS)
else
$(pkg)-precompiled: $($(PKG)_TARGET_BINARY) $($(PKG)_SETPCI_TARGET_BINARY) \
		$(pkg)-clean-ids
endif

$(pkg)-clean-ids:
	@$(RM) $(PCIUTILS_TARGET_IDS)

$(pkg)-clean:
	-$(SUBMAKE) -C $(PCIUTILS_DIR) clean

$(pkg)-uninstall: $(pkg)-clean-ids
	$(RM) $(PCIUTILS_TARGET_BINARY)
	$(RM) $(PCIUTILS_SETPCI_TARGET_BINARY)

$(PKG_FINISH)
