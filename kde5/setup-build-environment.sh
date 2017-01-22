#!/bin/sh
#
# Source this before building QT/KF5

PATH=/opt/Qt-5.7.1/bin:/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
export PATH

KF5_PREFIX=/opt/kf5
export KF5_PREFIX=/opt/kf5

export CMAKE_PREFIX_PATH="$KF5_PREFIX:$CMAKE_PREFIX_PATH"
