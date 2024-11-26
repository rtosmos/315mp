# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2020-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="fmsx"
PKG_VERSION="cf97a3c6da07d5f8e98c90c907ad987ffea432e0"
PKG_SHA256="1bdb6eee200bff59ca22c3244197785b055f995f6a9564a6e1a5dc381d4f4b4f"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/fmsx-libretro"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Port of fMSX 4.9 to the libretro API."
PKG_TOOLCHAIN="make"

make_target() {
  make
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp fmsx_libretro.so ${INSTALL}/usr/lib/libretro/
}