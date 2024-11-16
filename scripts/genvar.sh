#!/bin/bash

LOG=/var/log/genvar.log

if [ -n "${TARGET_DIR}" -a -n "${VAR_FILE_PATTERN}" ]; then
  mkdir -p ${TARGET_DIR}
  # generate variable replacements
  VARS=`export | awk '/declare -x */{print substr($3,1,index($3,"=")-1)}'`
  REPLACES=
  for V in ${VARS}; do
    ENV=${V}
    VAL="${!ENV}"
    REPL="-e 's#<${ENV}>#${VAL}#g'"
    if [ -n "${REPLACES}" ]; then
      REPLACES="${REPLACES} ${REPL}"
    else
      REPLACES="${REPL}"
    fi
  done
  # replace var files
  if [ -n "${REPLACES}" ]; then
    for V in `ls ${VAR_FILE_PATTERN}`; do
      if [ -f "${V}" ]; then
        DEST="${TARGET_DIR}/`basename ${V}`"
        cp "${V}" "${DEST}"
        echo "-i ${REPLACES} ${DEST}" | xargs sed
        echo "Generated var file ${DEST}...">>$LOG
      fi
    done
  fi
fi
