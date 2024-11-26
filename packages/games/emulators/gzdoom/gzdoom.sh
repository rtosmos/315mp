#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2021-present AmberELEC (https://github.com/AmberELEC)

. /etc/profile

ROM="${1##*/}"
PLATFORM="doom"
CONF="/storage/.config/distribution/configs/distribution.conf"

function get_setting() {
	#We look for the setting on the ROM first, if not found we search for platform and lastly we search globally
	PAT="s|^${PLATFORM}\[\"${ROM}\"\].*${1}=\(.*\)|\1|p"
	EES=$(sed -n "${PAT}" "${CONF}" | head -1)

	if [ -z "${EES}" ]; then
		PAT="s|^${PLATFORM}[\.-]${1}=\(.*\)|\1|p"
		EES=$(sed -n "${PAT}" "${CONF}" | head -1)
	fi

	if [ -z "${EES}" ]; then
		PAT="s|^global[\.-].*${1}=\(.*\)|\1|p"
		EES=$(sed -n "${PAT}" "${CONF}" | head -1)
	fi

	[ -z "${EES}" ] && EES="false"
}

# Show FPS
get_setting "show_fps"
if [ "${EES}" == "auto" ] || [ "${EES}" == "disabled" ] || [ "${EES}" == "false" ] || [ "${EES}" == "none" ] || [ "${EES}" == "0" ]; then
	SHOWFPS='0'
else
	SHOWFPS='1'
fi

EE_DEVICE=$(cat /storage/.config/.OS_ARCH)
RUN_DIR="/storage/roms/doom"
CONFIG="/storage/.config/distribution/gzdoom/gzdoom.ini"
SAVE_DIR="/storage/roms/gamedata/gzdoom"

if [ ! -L "/storage/.config/gzdoom" ]
then
  ln -sf "/storage/.config/distribution/gzdoom" "/storage/.config/gzdoom"
fi

if [ ! -f "/storage/.config/distribution/gzdoom/gzdoom.ini" ]
then
  cp -rf /usr/config/distribution/gzdoom/gzdoom.ini /storage/.config/distribution/gzdoom/
fi

mkdir -p ${SAVE_DIR}

params=" -config ${CONFIG} -savedir ${SAVE_DIR}"

# EXT can be wad, WAD, iwad, IWAD, pwad, PWAD or doom
EXT=${1#*.}

# If its not a simple wad (extension .doom) read the file and parse the data
if [ ${EXT} == "doom" ]; then
  dos2unix "${1}"
  while IFS== read -r key value; do
    if [ "$key" == "IWAD" ]; then
      params+=" -iwad $value"
    fi
    if [ "$key" == "MOD" ]; then
      params+=" -file $value"
    fi
    done < "${1}"
else
  params+=" -iwad ${1}"
fi

params+=" +gl_es 1 +vid_preferbackend 3 +cl_capfps 0 +vid_fps $SHOWFPS"

cd "${RUN_DIR}"
/usr/bin/gzdoom ${params} >/tmp/logs/gzdoom.log 2>&1
