#!/bin/bash

if [ -n "${APP_TIMEZONE}" ]; then
  ln -sf /usr/share/zoneinfo/${APP_TIMEZONE} /etc/localtime
  dpkg-reconfigure -f noninteractive tzdata
fi
