#!/bin/bash

LOG=/var/log/apt.log

[ -f /etc/apt/sources.list.d/debian.sources ] && \
  sed -i -e "s/deb.debian.org/${APT_MIRROR}/g" /etc/apt/sources.list.d/debian.sources
apt-get update>>$LOG
if [ -n "${APT_PACKAGES}" ]; then
  apt-get install -y ${APT_PACKAGES}>>$LOG
fi