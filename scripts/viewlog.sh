#!/bin/bash

EPG_LOG=/home/${CRON_USER}/epg.log
while true; do
  if [ -f "${EPG_LOG}" ]; then
    break
  fi
  sleep 1
done
tail -F ${EPG_LOG}