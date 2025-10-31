#!/bin/bash

LOG=/var/log/apt.log

[ -f /etc/apt/sources.list.d/debian.sources ] && \
  sed -i -e "s/deb.debian.org/${APT_MIRROR}/g" /etc/apt/sources.list.d/debian.sources
apt update 1>>$LOG 2>>$LOG
if [ -n "${APT_CORE_PACKAGES}" ]; then
  apt install -y ${APT_CORE_PACKAGES} 1>>$LOG 2>>$LOG
fi