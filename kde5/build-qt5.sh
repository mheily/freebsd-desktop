#!/bin/sh -x

# area51 port info:
#  http://src.mouf.net/area51/view/branches/qt-5.7/QT/devel/qt5-core/Makefile

version="5.7.1"

set -e
which python || pkg install -y python
which perl || pkg install -y perl5
which get || pkg install -y wget
which gmake || pkg install -y gmake
pkg list xcb >/dev/null || pkg install -y xcb
pkg list pcre >/dev/null || pkg install -y pcre
pkg list pkgconf >/dev/null || pkg install -y pkgconf
pkg list libGL >/dev/null || pkg install -y libGL
pkg list inputproto >/dev/null || pkg install -y inputproto
set +e


topdir=/tmp/qt5

mkdir -p $topdir
cd $topdir

fetch() {
	url="http://download.qt.io/official_releases/qt/5.7/5.7.1/single/qt-everywhere-opensource-src-5.7.1.tar.xz"
	wget -nc $url
}

unpack() {
	cd $topdir
	test -d qt-everywhere-opensource-src-5.7.1 || {
		tar xf *.xz
	}
}

patch() {
	# Unknown platform. Qt WebEngine only supports Linux, Windows, and OS X.
 	set -ex
	cd $topdir/qt-everywhere-opensource-src-5.7.1/qtwebengine
	#FIXME:need this? /usr/bin/patch -p0<~/qtwebengine.patch
 	set +ex
}

configure() {
 	set -ex
	cd $topdir/qt-everywhere-opensource-src-5.7.1

 	# Reenable this to compile everything
	#experimental_flags="-silent -skip qt3d -skip qtwebengine -skip qtscript"
	experimental_flags="-silent -skip qt3d"

	./configure \
		-prefix /opt/Qt-5.7.1 \
		-release \
		-nomake tests -nomake examples \
		-opensource -confirm-license \
		-qt-xcb \
		$experimental_flags \
		2>&1 | tee ../../configure.log

#	-no-accessibility -no-gif -no-libpng -no-libjpeg -no-openssl \
#		-no-widgets -no-cups -no-iconv -no-dbus --no-opengl \
#		-no-alsa -no-egl -no-evdev -no-feature-concurrent \
#		-no-fontconfig -no-freetype -no-gtk -no-harfbuzz -no-libudev \
#		-no-pulseaudio -no-xcb -no-xinput2 -no-xkb -no-xcb-xlib \
#		-no-xkbcommon -no-xrender -no-xshape -no-xsync -no-libinput

	cd ..

	set +ex
}

build() {
 	set -ex
	cd $topdir/qt-everywhere-opensource-src-5.7.1
	gmake -j 8 2>&1 | tee $topdir/build.log
	set +ex
}

if [ -z "$1" ] ; then
	fetch
	unpack
	patch
	configure
	build
else
	eval $1
fi
