# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit qt4-build-multilib
MULTILIB_USEDEP_HACK='abi_x86_64(-)?'

DESCRIPTION="The WebKit module for the Qt toolkit"
SRC_URI+=" http://files.adjust.com/qt-${PV}-wkhtmltopdf.patch"

if [[ ${QT4_BUILD_TYPE} == release ]]; then
	KEYWORDS="~amd64"
fi

IUSE="+gstreamer icu +jit wkhtmltopdf"

# libxml2[!icu?] is needed for bugs 407315 and 411091
DEPEND="
	>=dev-db/sqlite-3.8.3:3[${MULTILIB_USEDEP_HACK}]
	~dev-qt/qtcore-${PV}[aqua=,debug=,ssl,wkhtmltopdf=,${MULTILIB_USEDEP_HACK}]
	~dev-qt/qtgui-${PV}[aqua=,debug=,wkhtmltopdf=,${MULTILIB_USEDEP_HACK}]
	~dev-qt/qtxmlpatterns-${PV}[aqua=,debug=,wkhtmltopdf=,${MULTILIB_USEDEP_HACK}]
	>=x11-libs/libX11-1.5.0-r1[${MULTILIB_USEDEP_HACK}]
	>=x11-libs/libXrender-0.9.7-r1[${MULTILIB_USEDEP_HACK}]
	gstreamer? (
		dev-libs/glib:2[${MULTILIB_USEDEP_HACK}]
		dev-libs/libxml2:2[!icu?,${MULTILIB_USEDEP_HACK}]
		>=media-libs/gstreamer-0.10.36-r1:0.10[${MULTILIB_USEDEP_HACK}]
		>=media-libs/gst-plugins-base-0.10.36-r1:0.10[${MULTILIB_USEDEP_HACK}]
	)
	icu? ( dev-libs/icu:=[${MULTILIB_USEDEP_HACK}] )
"
RDEPEND="${DEPEND}"

PATCHES=(
	"${FILESDIR}/4.8.2-javascriptcore-x32.patch"
)

QT4_TARGET_DIRECTORIES="
	src/3rdparty/webkit/Source/JavaScriptCore
	src/3rdparty/webkit/Source/WebCore
	src/3rdparty/webkit/Source/WebKit/qt"

QCONFIG_ADD="webkit"
QCONFIG_DEFINE="QT_WEBKIT"

src_prepare() {
	use wkhtmltopdf && epatch "${DISTDIR}/qt-${PV}-wkhtmltopdf.patch"

	# Remove -Werror from CXXFLAGS
	sed -i -e '/QMAKE_CXXFLAGS\s*+=/ s:-Werror::g' \
		src/3rdparty/webkit/Source/WebKit.pri || die

	# Fix version number in generated pkgconfig file (bug 406443)
	sed -i -e 's/^isEmpty(QT_BUILD_TREE)://' \
		src/3rdparty/webkit/Source/WebKit/qt/QtWebKit.pro || die

	# Prevent automagic dependency on qt-mobility (bug 547350)
	sed -i -e 's/contains(MOBILITY_CONFIG,\s*\w\+)/false/' \
		src/3rdparty/webkit/Source/WebCore/features.pri || die

	if use icu; then
		sed -i -e '/CONFIG\s*+=\s*text_breaking_with_icu/ s:^#\s*::' \
			src/3rdparty/webkit/Source/JavaScriptCore/JavaScriptCore.pri || die
	fi

	qt4-build-multilib_src_prepare
}

multilib_src_configure() {
	local myconf=(
		-webkit
		-system-sqlite
		$(qt_use icu)
		$(qt_use jit javascript-jit)
		$(use gstreamer || echo -DENABLE_VIDEO=0)
	)
	qt4_multilib_src_configure
}
