#!/bin/bash

set -x

usage() {
  base="$(basename "$0")"
  cat <<EOUSAGE
usage: $base [-r] <arch>
Install specific packages to build grafana for either armv6, armv7 or arm64
Use -r for release package
Available arch:
  $base armv6
  $base armv7
  $base arm64
EOUSAGE
}

install_phjs() {
  PHJSURL="https://github.com/fg2it/phantomjs-on-raspberry/releases/download/${PHJSV}"
  PHJS=/tmp/${ARM}/phantomjs
  mkdir -p /tmp/${ARM}
  curl -sSL ${PHJSURL}/phantomjs -o ${PHJS}
  chmod a+x ${PHJS}
}

armv6_install_cross(){
  cd /tmp
  git clone https://github.com/fg2it/cross-rpi1b.git
  CROSSPATH="/tmp/cross-rpi1b/arm-rpi-4.9.3-linux-gnueabihf/bin/"
  CC=${CROSSPATH}/arm-linux-gnueabihf-gcc
}

armv7_install_cross() {
  apt-get install -y gcc-arm-linux-gnueabihf
  CC=arm-linux-gnueabihf-gcc
}

arm64_install_cross() {
  apt-get install -y gcc-aarch64-linux-gnu
  CC=aarch64-linux-gnu-gcc
}

build() {
  cd $GOPATH/src/github.com/grafana/grafana
  go run build.go                   \
     -pkg-arch=${ARCH}              \
     -goarch=${ARM}                 \
     -cgo-enabled=1                 \
     -cc=$CC                        \
     -phjs=${PHJS}                  \
     -includeBuildNumber=${includeBuildNumber} \
         build                      \
         pkg-deb
}


includeBuildNumber="true"
if [ "$1" == "-r" ]; then
  echo "Package for release"
  includeBuildNumber="false"
  shift
fi

if (( $# != 1 )); then
	usage >&2
	exit 1
fi

ARM="$1"

case "$ARM" in
  armv6)
    PHJSV="v2.1.1-wheezy-jessie-armv6"
    armv6_install_cross
    ARCH="armhf"
    ;;
  armv7)
    PHJSV="v2.1.1-wheezy-jessie"
    armv7_install_cross
    ARCH="armhf"
    ;;
  arm64)
    PHJSV="v2.1.1-stretch-arm64"
    arm64_install_cross
    ARCH="arm64"
    ;;
  *)
    echo >&2 'error: unknown arch:' "$ARM"
    usage >&2
    exit 1
    ;;
esac

install_phjs
build
