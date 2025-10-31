#!/bin/bash

LOG=/var/log/packages.log

if [ -n "${APT_PACKAGES}" ]; then
  apt install -y ${APT_PACKAGES} 1>>$LOG 2>>$LOG
fi