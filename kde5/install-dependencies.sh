#!/bin/sh

#------------- QT5 dependencies

# TODO: add more packages from http://doc.qt.io/qt-5/linux-requirements.html
#   - opengl
#   - gstreamer
#   - qtwebengine stuff   http://doc.qt.io/qt-5/qtwebengine-platform-notes.html
#

pkg install -y python xcb-util-wm libxkbcommon gmake

#------------- kdesrc-build dependencies

pkg install -y p5-XML-Parser bzr doxygen flex bison rsync \
	gpgme-cpp

#------------- KF5 dependencies

pkg install -y lmdb xcb-util-cursor gamin iceauth

mkdir -p /opt/kf5
chown plasma-build /opt/kf5

# ------------ Wayland dependencies

pkg install -y autoconf automake libtool multimedia/v4l_compat libevdev

# build x11/libinput and x11/wayland, install these packages


# -------------- Shitty workarounds

# needed by the kactivities-stats build, b/c they don't /usr/local/include
cd /usr/include ; ln -sf /usr/local/include/boost .
