#!/bin/sh -ex

# build all from start to finish

sudo ./install-dependencies.sh
./build-wayland.sh
sudo ./build-wayland.sh install
./build-qt5.sh
sudo ./build-qt5.sh install

echo 'XXX-FIXME below needs more setup'
exit 1

. ~/setup-build-environment.sh
cd kdesrc-build
./kdesrc-build --include-dependencies plasma-desktop
./kdesrc-build applications
./kdesrc-build --include-dependencies kdevelop

