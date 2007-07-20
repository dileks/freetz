LIBPNG_VERSION:=1.2.10
LIBPNG_LIB_VERSION:=$(LIBPNG_VERSION)
LIBPNG_SOURCE:=libpng-$(LIBPNG_VERSION).tar.gz
LIBPNG_SITE:=http://oss.oetiker.ch/rrdtool/pub/libs/
LIBPNG_MAKE_DIR:=$(MAKE_DIR)/libs
LIBPNG_DIR:=$(SOURCE_DIR)/libpng-$(LIBPNG_VERSION)
LIBPNG_BINARY:=$(LIBPNG_DIR)/lib/libpng.so.$(LIBPNG_LIB_VERSION)
LIBPNG_STAGING_BINARY:=$(TARGET_TOOLCHAIN_STAGING_DIR)/usr/lib/libpng.so.$(LIBPNG_LIB_VERSION)
LIBPNG_TARGET_DIR:=root/usr/lib
LIBPNG_TARGET_BINARY:=$(LIBPNG_TARGET_DIR)/libpng.so.$(LIBPNG_LIB_VERSION)

$(DL_DIR)/$(LIBPNG_SOURCE): | $(DL_DIR)
	wget -P $(DL_DIR) $(LIBPNG_SITE)/$(LIBPNG_SOURCE)

$(LIBPNG_DIR)/.unpacked: $(DL_DIR)/$(LIBPNG_SOURCE)
	tar -C $(SOURCE_DIR) $(VERBOSE) -xzf $(DL_DIR)/$(LIBPNG_SOURCE)
#	for i in $(LIBPNG_MAKE_DIR)/patches/*.libpng.patch; do \
#		patch -d $(LIBPNG_DIR) -p0 < $$i; \
#	done
	touch $@

$(LIBPNG_DIR)/.configured: $(LIBPNG_DIR)/.unpacked
	( cd $(LIBPNG_DIR); rm -f config.{cache,status} ; \
		$(TARGET_CONFIGURE_OPTS) \
		PATH="$(TARGET_TOOLCHAIN_PATH)" \
		CC="$(TARGET_CC)" \
		LD="$(TARGET_LD)" \
		CFLAGS="$(TARGET_CFLAGS) -I$(TARGET_TOOLCHAIN_STAGING_DIR)/usr/include" \
		CPPFLAGS="-I$(TARGET_TOOLCHAIN_STAGING_DIR)/usr/include" \
		LDFLAGS="-L$(TARGET_TOOLCHAIN_STAGING_DIR)/usr/lib" \
		./configure \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--program-prefix="" \
		--program-suffix="" \
		--prefix=/usr \
		--exec-prefix=/usr \
		--bindir=/usr/bin \
		--datadir=/usr/share \
		--includedir=/usr/include \
		--infodir=/usr/share/info \
		--libdir=/usr/lib \
		--libexecdir=/usr/lib \
		--localstatedir=/var \
		--mandir=/usr/share/man \
		--sbindir=/usr/sbin \
		--sysconfdir=/etc \
		$(DISABLE_NLS) \
		$(DISABLE_LARGEFILE) \
		--enable-shared \
		--enable-static \
	);
	touch $@

$(LIBPNG_BINARY): $(LIBPNG_DIR)/.configured
	PATH=$(TARGET_TOOLCHAIN_PATH) \
		$(MAKE) -C $(LIBPNG_DIR)

$(LIBPNG_STAGING_BINARY): $(LIBPNG_BINARY)
	PATH=$(TARGET_TOOLCHAIN_PATH) $(MAKE1) \
		instroot="$(TARGET_TOOLCHAIN_STAGING_DIR)" \
		-C $(LIBPNG_DIR) install

$(LIBPNG_TARGET_BINARY): $(LIBPNG_STAGING_BINARY)
	cp -a $(TARGET_TOOLCHAIN_STAGING_DIR)/usr/lib/libpng*.so* $(LIBPNG_TARGET_DIR)/
	$(TARGET_STRIP) $@

libpng: $(LIBPNG_STAGING_BINARY)

libpng-precompiled: uclibc libpng $(LIBPNG_TARGET_BINARY)

libpng-source: $(LIBPNG_DIR)/.unpacked

libpng-clean:
	-$(MAKE) -C $(LIBPNG_DIR) clean
	rm -f $(TARGET_TOOLCHAIN_STAGING_DIR)/usr/lib/libpng*

libpng-uninstall:
	rm -f $(LIBPNG_TARGET_DIR)/libpng*.so*

libpng-dirclean:
	rm -rf $(LIBPNG_DIR)
