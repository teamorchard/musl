# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6
QT5_MODULE="qtbase"
inherit qt5-build

DESCRIPTION="Cross-platform application development framework"

if [[ ${QT5_BUILD_TYPE} == release ]]; then
	KEYWORDS="~amd64 ~arm ~arm64 ~hppa ~ppc ~ppc64 ~x86"
fi

IUSE="icu libcxx libcxxabi systemd"

DEPEND="
	dev-libs/double-conversion:=
	dev-libs/glib:2
	dev-libs/libpcre2[pcre16,unicode]
	sys-libs/zlib
	icu? ( dev-libs/icu:= )
	!icu? ( virtual/libiconv )
	systemd? ( sys-apps/systemd:= )
	libcxx? (
		sys-devel/clang:=
		sys-libs/libcxx:=
		libcxxabi? ( sys-libs/libcxxabi:= )
	)
"
RDEPEND="${DEPEND}"

PATCHES=(
	"${FILESDIR}/${P}-avx.patch"
	"${FILESDIR}/${PN}-5.9.3-musl-iconv.patch"
)

QT5_TARGET_SUBDIRS=(
	src/tools/bootstrap
	src/tools/moc
	src/tools/rcc
	src/tools/qfloat16-tables
	src/corelib
	src/tools/qlalr
	doc
)

src_configure() {
	if use libcxxabi; then
		eapply "${FILESDIR}/${PN}-clang-libc++abi.patch"
	fi

	local myconf=(
		$(qt_use icu)
		$(qt_use !icu iconv)
		$(qt_use systemd journald)
		$(if use libcxx ; then echo "-platform linux-clang-libc++" ; fi)
	)
	qt5-build_src_configure
}

src_install() {
	qt5-build_src_install

	local flags=(
		ALSA CUPS DBUS EGL EGLFS EGL_X11 EVDEV FONTCONFIG FREETYPE
		HARFBUZZ IMAGEFORMAT_JPEG IMAGEFORMAT_PNG LIBPROXY MITSHM
		OPENGL OPENSSL OPENVG PULSEAUDIO SHAPE SSL TSLIB XCURSOR
		XFIXES XKB XRANDR XRENDER XSYNC ZLIB
	)

	for flag in ${flags[@]}; do
		cat >> "${D%/}"/${QT5_HEADERDIR}/QtCore/qconfig.h <<- _EOF_ || die

			#if defined(QT_NO_${flag}) && defined(QT_${flag})
			# undef QT_NO_${flag}
			#elif !defined(QT_NO_${flag}) && !defined(QT_${flag})
			# define QT_NO_${flag}
			#endif
		_EOF_
	done
}
