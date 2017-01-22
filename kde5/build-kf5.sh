#!/bin/sh -x
# 
# See: http://www.linuxfromscratch.org/blfs/view/svn/kde/kf5-intro.html
#

version="5.29"

mkdir -p kf5
cd kf5

KF5_PREFIX=/opt/kf5
export KF5_PREFIX=/opt/kf5

fetch() {
	url="http://download.kde.org/stable/frameworks/${version}/"
	wget -nc -r -nH --cut-dirs=3 -A '*.xz' -np $url
}

unpack() {
}

build_ecm() {
	cd $HOME
	test -d extra-cmake-modules || git clone git://anongit.kde.org/extra-cmake-modules
	cd extra-cmake-modules
	cmake -DCMAKE_INSTALL_PREFIX=$KF5_PREFIX -DCMAKE_PREFIX_PATH=/opt/Qt-5.7.1/lib/cmake . 
	make 
	make install
	exit 0
}

build() {
	pkg=$1

	tar zxf $pkg-*.xz
	cd `find ./ -name "${pkg}*" -type d`
	cmake .
	make
	make install
}

if [ -z "$1" ] ; then
#       fetch

# FIXME: manually do this, and edit the path inside the file
#	cp kdesrc-buildrc-kf5-sample ~/.kdesrc-buildrc

	set -ex
	test -d /opt/kf5/share/ECM || build_ecm
	cd ../kdesrc-build
	./kdesrc-build --reconfigure
	set +ex
else
	set -ex
        eval $1
	set +ex
fi

exit 0
