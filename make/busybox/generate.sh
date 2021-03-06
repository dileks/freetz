#!/bin/bash
# Generates a Config.in(.busybox) of Busybox for Freetz
BBDIR="$(dirname $(readlink -f $0))"
BBVER="$(sed -n 's/$(call PKG_INIT_BIN, \(.*\))/\1/p' $BBDIR/busybox.mk)"
BBOUT="$BBDIR/Config.in.busybox"
BBDEP="$BBDIR/busybox.rebuild-subopts.mk.in"

default_value() { # matches int and bool values
	sed -r -i "/^config FREETZ_BUSYBOX_$1$/{N;N;N;N;N;s/(\tdefault )[^\n]*/\1$2/}" "$BBOUT"
}

default_string() {
	sed -r -i "/^config FREETZ_BUSYBOX_$1$/{N;N;N;N;N;s#(\tdefault )[^\n]*#\1\"$2\"#}" "$BBOUT"
}

default_choice() {
	sed -r -i "/^[ \t]*prompt \"$1\"/{N;N;N;N;N;s/(\tdefault )[^\n]*/\1$2/}" "$BBOUT"
}

depends_on() {
	sed -r -i "/^config FREETZ_BUSYBOX_$1/{N;N;N;N;N;s/(\thelp\n)/\tdepends on $2\n\1/}" "$BBOUT"
}

echo -n "unpacking ..."
rm -rf "$BBDIR/busybox-$BBVER"
tar xf "$BBDIR/../../dl/busybox-$BBVER.tar.bz2" -C "$BBDIR"

echo -n " patching ..."
cd "$BBDIR/busybox-$BBVER/"
for p in $BBDIR/patches/*.patch; do
	patch -p0 < $p >/dev/null
done

echo -n " building ..."
FREETZ_GENERATE_CONFIG_IN_ONLY=y ./scripts/gen_build_files.sh "$BBDIR/busybox-$BBVER/" "$BBDIR/busybox-$BBVER/" >/dev/null

echo -n " parsing ..."
echo -e "\n### Do not edit this file! Run generate.sh to create it. ###\n\n" > "$BBOUT"
$BBDIR/../../tools/parse-config Config.in >> "$BBOUT" 2>/dev/null
rm -rf "$BBDIR/busybox-$BBVER"

echo -n " searching ..."
nonfeature_symbols=""
feature_symbols=""
for symbol in $(sed -n 's/^config //p' "$BBOUT"); do
	if [ "${symbol:0:8}" != "FEATURE_" ]; then
		nonfeature_symbols="${nonfeature_symbols}${nonfeature_symbols:+|}${symbol}"
	else
		feature_symbols="${feature_symbols}${feature_symbols:+|}${symbol}"
	fi
done

echo -n " replacing ..."
sed -i -r \
	-e "s,([ (!])(${feature_symbols})($|[ )]),\1FREETZ_BUSYBOX_\2\3,g" \
	-e "/^[ \t#]*(config|default|depends|select)/{s,([ (!])(${nonfeature_symbols})($|[ )]),\1FREETZ_BUSYBOX_\2\3,g}" \
	"$BBOUT"
sed -i '/^mainmenu /d' "$BBOUT"
sed -i 's!\(^#*[\t ]*default \)y\(.*\)$!\1n\2!g;' "$BBOUT"

echo -n " finalizing ..."
echo -e "\n### Do not edit this file! Run generate.sh to create it. ###\n\n" > "$BBDEP"
sed -n 's/^config /$(PKG)_REBUILD_SUBOPTS += /p' "$BBOUT" | sort -u >> "$BBDEP"

default_value MD5SUM "y" # for modsave
default_value FEATURE_COPYBUF_KB 64
default_value FEATURE_VI_MAX_LEN 1024
default_value SUBST_WCHAR 0
default_value LAST_SUPPORTED_WCHAR 0
default_string BUSYBOX_EXEC_PATH "/bin/busybox"
default_choice "Buffer allocation policy" FREETZ_BUSYBOX_FEATURE_BUFFERS_GO_ON_STACK
depends_on LOCALE_SUPPORT "!FREETZ_TARGET_UCLIBC_0_9_28"
depends_on FEATURE_IPV6 "FREETZ_TARGET_IPV6_SUPPORT"
depends_on KLOGD "FREETZ_AVM_HAS_PRINTK"

echo " done."
