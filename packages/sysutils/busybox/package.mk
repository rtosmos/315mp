# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)
# Copyright (C) 2022-present AmberELEC (https://github.com/AmberELEC)

PKG_NAME="busybox"
PKG_VERSION="1.36.0"
PKG_SHA256="542750c8af7cb2630e201780b4f99f3dcceeb06f505b479ec68241c1e6af61a5"
PKG_LICENSE="GPL"
PKG_SITE="http://www.busybox.net"
PKG_URL="https://busybox.net/downloads/${PKG_NAME}-${PKG_VERSION}.tar.bz2"
PKG_DEPENDS_HOST="toolchain:host"
PKG_DEPENDS_TARGET="toolchain hdparm hd-idle dosfstools e2fsprogs zip usbutils parted procps-ng gptfdisk libtirpc cryptsetup"
PKG_DEPENDS_INIT="toolchain libtirpc"
PKG_LONGDESC="BusyBox combines tiny versions of many common UNIX utilities into a single small executable."

# nano text editor
if [ "${NANO_EDITOR}" = "yes" ]; then
  PKG_DEPENDS_TARGET+=" nano"
fi

# nfs support
if [ "${NFS_SUPPORT}" = yes ]; then
  PKG_DEPENDS_TARGET+=" rpcbind"
fi

if [ "${TARGET_ARCH}" = "x86_64" ]; then
  PKG_DEPENDS_TARGET+=" pciutils"
fi

pre_build_target() {
  PKG_MAKE_OPTS_TARGET="ARCH=${TARGET_ARCH} \
                        HOSTCC=${HOST_CC} \
                        CROSS_COMPILE=${TARGET_PREFIX} \
                        KBUILD_VERBOSE=1 \
                        install"

  mkdir -p ${PKG_BUILD}/.${TARGET_NAME}
  cp -RP ${PKG_BUILD}/* ${PKG_BUILD}/.${TARGET_NAME}
}

pre_build_init() {
  PKG_MAKE_OPTS_INIT="ARCH=${TARGET_ARCH} \
                      HOSTCC=${HOST_CC} \
                      CROSS_COMPILE=${TARGET_PREFIX} \
                      KBUILD_VERBOSE=1 \
                      install"

  mkdir -p ${PKG_BUILD}/.${TARGET_NAME}-init
  cp -RP ${PKG_BUILD}/* ${PKG_BUILD}/.${TARGET_NAME}-init
}

configure_target() {
  cd ${PKG_BUILD}/.${TARGET_NAME}
    find_file_path config/busybox-target.conf
    cp ${FOUND_PATH} .config

    # set install dir
    sed -i -e "s|^CONFIG_PREFIX=.*$|CONFIG_PREFIX=\"${INSTALL}/usr\"|" .config

    if [ ! "${CRON_SUPPORT}" = "yes" ]; then
      sed -i -e "s|^CONFIG_CROND=.*$|# CONFIG_CROND is not set|" .config
      sed -i -e "s|^CONFIG_FEATURE_CROND_D=.*$|# CONFIG_FEATURE_CROND_D is not set|" .config
      sed -i -e "s|^CONFIG_CRONTAB=.*$|# CONFIG_CRONTAB is not set|" .config
      sed -i -e "s|^CONFIG_FEATURE_CROND_SPECIAL_TIMES=.*$|# CONFIG_FEATURE_CROND_SPECIAL_TIMES is not set|" .config
    fi

    if [ ! "${SAMBA_SUPPORT}" = yes ]; then
      sed -i -e "s|^CONFIG_FEATURE_MOUNT_CIFS=.*$|# CONFIG_FEATURE_MOUNT_CIFS is not set|" .config
    fi

    CFLAGS+=" -I${SYSROOT_PREFIX}/usr/include/tirpc"

    LDFLAGS+=" -fwhole-program"

    make oldconfig
}

configure_init() {
  cd ${PKG_BUILD}/.${TARGET_NAME}-init
    find_file_path config/busybox-init.conf
    cp ${FOUND_PATH} .config

    # set install dir
    sed -i -e "s|^CONFIG_PREFIX=.*$|CONFIG_PREFIX=\"${INSTALL}/usr\"|" .config

    CFLAGS+=" -I${SYSROOT_PREFIX}/usr/include/tirpc"

    LDFLAGS+=" -fwhole-program"

    make oldconfig
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
    cp ${PKG_DIR}/scripts/createlog ${INSTALL}/usr/bin/
    cp ${PKG_DIR}/scripts/lsb_release ${INSTALL}/usr/bin/
    cp ${PKG_DIR}/scripts/sudo ${INSTALL}/usr/bin/

  mkdir -p ${INSTALL}/usr/lib/libreelec
    cp ${PKG_DIR}/scripts/functions ${INSTALL}/usr/lib/libreelec
    cp ${PKG_DIR}/scripts/fs-resize ${INSTALL}/usr/lib/libreelec
    sed -e "s/@DISTRONAME@/${DISTRONAME}/g" \
        -i ${INSTALL}/usr/lib/libreelec/fs-resize

  mkdir -p ${INSTALL}/etc
    cp ${PKG_DIR}/config/profile ${INSTALL}/etc
    cp ${PKG_DIR}/config/inputrc ${INSTALL}/etc
    cp ${PKG_DIR}/config/suspend-modules.conf ${INSTALL}/etc

  # /etc/fstab is needed by...
    touch ${INSTALL}/etc/fstab

  # /etc/machine-id, needed by systemd and dbus
    ln -sf /storage/.cache/systemd-machine-id ${INSTALL}/etc/machine-id

  # /etc/mtab is needed by udisks etc...
    ln -sf /proc/self/mounts ${INSTALL}/etc/mtab

  # create /etc/hostname
    ln -sf /proc/sys/kernel/hostname ${INSTALL}/etc/hostname
}

post_install() {
  echo "chmod 4755 ${INSTALL}/usr/bin/busybox" >> ${FAKEROOT_SCRIPT}
  echo "chmod 000 ${INSTALL}/usr/cache/shadow" >> ${FAKEROOT_SCRIPT}

  add_user root "${ROOT_PASSWORD}" 0 0 "Root User" "/storage" "/bin/sh"
  add_group root 0
  add_group users 100

  add_user nobody x 65534 65534 "Nobody" "/" "/bin/sh"
  add_group nogroup 65534

  enable_service fs-resize.service
  enable_service shell.service
  enable_service show-version.service
  enable_service var.mount
  listcontains "${FIRMWARE}" "rpi-eeprom" && enable_service rpi-flash-firmware.service

  # cron support
  if [ "${CRON_SUPPORT}" = "yes" ]; then
    mkdir -p ${INSTALL}/usr/lib/systemd/system
      cp ${PKG_DIR}/system.d.opt/cron.service ${INSTALL}/usr/lib/systemd/system
      enable_service cron.service
    mkdir -p ${INSTALL}/usr/share/services
      cp -P ${PKG_DIR}/default.d/*.conf ${INSTALL}/usr/share/services
      cp ${PKG_DIR}/system.d.opt/cron-defaults.service ${INSTALL}/usr/lib/systemd/system
      enable_service cron-defaults.service
  fi
}

makeinstall_init() {
  mkdir -p ${INSTALL}/bin
    ln -sf busybox ${INSTALL}/usr/bin/sh
    chmod 4755 ${INSTALL}/usr/bin/busybox

  mkdir -p ${INSTALL}/etc
    touch ${INSTALL}/etc/fstab
    ln -sf /proc/self/mounts ${INSTALL}/etc/mtab

  if find_file_path initramfs/platform_init; then
    cp ${FOUND_PATH} ${INSTALL}
    sed -e "s/@BOOT_LABEL@/${DISTRO_BOOTLABEL}/g" \
        -e "s/@DISK_LABEL@/${DISTRO_DISKLABEL}/g" \
        -i ${INSTALL}/platform_init
    chmod 755 ${INSTALL}/platform_init
  fi

  cp ${PKG_DIR}/scripts/functions ${INSTALL}
  cp ${PKG_DIR}/scripts/init ${INSTALL}
  sed -e "s/@DISTRONAME@/${DISTRONAME}/g" \
      -e "s/@KERNEL_NAME@/${KERNEL_NAME}/g" \
      -e "s/@SYSTEM_SIZE@/${SYSTEM_SIZE}/g" \
      -i ${INSTALL}/init
  chmod 755 ${INSTALL}/init
}