# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2019-present Team LibreELEC (https://libreelec.tv)
# Copyright (C) 2022-present AmberELEC (https://amberelec.org)

PKG_NAME="libusb"
PKG_VERSION="1.0.25"
PKG_SHA256="8a28ef197a797ebac2702f095e81975e2b02b2eeff2774fa909c78a74ef50849"
PKG_LICENSE="LGPLv2.1"
PKG_SITE="http://libusb.info/"
PKG_URL="https://github.com/libusb/libusb/releases/download/v${PKG_VERSION}/libusb-${PKG_VERSION}.tar.bz2"
PKG_DEPENDS_TARGET="toolchain systemd"
PKG_LONGDESC="The libusb project's aim is to create a Library for use by user level applications to USB devices."

PKG_CONFIGURE_OPTS_TARGET="--enable-shared \
            --enable-static \
            --disable-log \
            --disable-debug-log \
            --enable-udev \
            --disable-examples-build"

pre_configure_target() {
  export CFLAGS="${CFLAGS} -Wno-error=maybe-uninitialized"
}