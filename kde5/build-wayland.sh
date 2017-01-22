#!/bin/sh -x

topdir=`pwd`/wayland
mkdir -p $topdir
cd $topdir

fetch() {
	test -d freebsd-ports-graphics || {
		git clone https://github.com/freebsd/freebsd-ports-graphics.git wayland
		cd wayland && git checkout -b wayland
	}
}

unpack() {
}

patch() {
}

configure() {
}

build() {
	# todo: build wayland and libinput, install packages
	cd $topdir/freebsd-ports-graphics/graphics/wayland
	make package
	cd $topdir/freebsd-ports-graphics/x11/libinput
	make package
}

install() {
	cd $topdir/freebsd-ports-graphics/graphics/wayland
	make install-package
	cd $topdir/freebsd-ports-graphics/x11/libinput
	make install-package
}

set -ex
if [ -z "$1" ] ; then
	fetch
	unpack
	patch
	configure
	build
	test `id -u` -ne 0 || install
else
	eval $1
fi
