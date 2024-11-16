#!/bin/bash

while [ $# -gt 0 ]; do
  BG=0
  SCRIPT=$1
  if [ "${SCRIPT:0:1}" = "+" ]; then
    BG=1
    LEN=$((${#SCRIPT}-1))
    SCRIPT=${SCRIPT:1:$LEN}
  fi
  IFS=':' read -ra ARR <<< "$SCRIPT"
  if [ ${#ARR[@]} -gt 1 ]; then
    SRC=${ARR[0]}
    SCRIPT=${ARR[1]}
  else
    SRC=$SCRIPT
  fi
  if [ -f /scripts/${SRC}.sh ]; then
    cp /scripts/${SRC}.sh ~/${SCRIPT}.sh
    chmod +x ~/${SCRIPT}.sh
    echo "--- ${SCRIPT}.sh ---"
    if [ $BG -eq 1 ]; then
      ~/${SCRIPT}.sh &
    else
      ~/${SCRIPT}.sh
    fi
  fi
  shift
done
