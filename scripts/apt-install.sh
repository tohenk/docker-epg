#!/bin/bash

LOG=/var/log/packages.log

if [ -n "${APT_PACKAGES}" ]; then
  apt-get install -y ${APT_PACKAGES}>>$LOG
fi