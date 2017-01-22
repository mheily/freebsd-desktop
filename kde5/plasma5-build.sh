#!/bin/sh -x

version="5.8.5"

mkdir -p plasma5
cd plasma5

fetch() {
	url="http://download.kde.org/stable/plasma/${version}/"
	wget -r -nH --cut-dirs=3 -A '*.xz' -np $url
}

build() {
}

# fetch
build
