#!/bin/bash

for D in $CRON_DIR /config; do
  [ -d "$D" ] && dos2unix $D/*
done