#!/bin/bash

LOG=/var/log/apt.log

if [ -n "${APT_MIRROR}" ]; then
  [ -f /etc/apt/sources.list.d/debian.sources ] && \
    sed -i -e "s/deb.debian.org/${APT_MIRROR}/g" /etc/apt/sources.list.d/debian.sources
fi
apt update 1>>${LOG} 2>&1
if [ -n "${APT_CORE_PACKAGES}" ]; then
  apt install -y ${APT_CORE_PACKAGES} 1>>${LOG} 2>&1
fi