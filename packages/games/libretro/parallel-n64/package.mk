# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)
# Copyright (C) 2021-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="parallel-n64"
PKG_VERSION="49eadb4da85f7e3bd59b60f61e8fd5dbfb9f07d5"
PKG_SHA256="b469d447c1d1bb46d7777565848f6ecd4426a9f240ccb192910e00353ce24ad1"
PKG_REV="2"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/parallel-n64"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain ${OPENGLES}"
PKG_LONGDESC="Optimized/rewritten Nintendo 64 emulator made specifically for Libretro. Originally based on Mupen64 Plus."
PKG_TOOLCHAIN="make"

if [[ "${DEVICE}" =~ RG552 ]]; then
  PKG_MAKE_OPTS_TARGET=" platform=unix_RK3399"
else
  PKG_MAKE_OPTS_TARGET=" platform=unix_RK3326"
fi

if [[ "${DEVICE}" == RG351P ]] || [[ "${DEVICE}" == RG351V ]]; then
  PKG_PATCH_DIRS="rumble"
fi

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp parallel_n64_libretro.so ${INSTALL}/usr/lib/libretro/
}
