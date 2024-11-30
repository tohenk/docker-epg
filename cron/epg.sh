#!/bin/bash

. $(dirname $0)/epg.env
. $(dirname $0)/guides.env

BUILD_DIR=/build
OUT_DIR=$BUILD_DIR/$EPG_GUIDES_DIR
LOCK_FILE=$BUILD_DIR/.lock
RUN_FILE=$BUILD_DIR/.run
ONCE_FILE=$BUILD_DIR/.once

[ -f $LOCK_FILE ] && exit
if [ "x$1" = "xauto" ]; then
  if [ -f $RUN_FILE ]; then
    rm -f $RUN_FILE
  else
    [ -f $ONCE_FILE ] && exit
    touch $ONCE_FILE
  fi
fi

watch_completion() {
  SITE=$1
  LOG=$2
  TMO=$3
  [ -z "$TMO" ] && TMO=${WATCH_TIMEOUT:-3600}
  START=$(date +%s)
  while true; do
    sleep 1
    if [ -f $LOG ]; then
      LINE=$(echo "`tail -n 1 $LOG | grep 'done in'`" | xargs)
      if [ -n "$LINE" ]; then
        echo "Site $SITE: $LINE"
        break
      fi
    fi
    D=$(($(date +%s)-$START))
    if [ $D -gt $TMO ]; then
      break
    fi
  done
}

echo "=== `basename $0` ==="

touch $LOCK_FILE

cd $BUILD_DIR
if [ ! -d $BUILD_DIR/epg ]; then
  echo "Cloning EPG source..."
  git clone https://github.com/iptv-org/epg.git epg && cd $BUILD_DIR/epg
else
  echo "Updating EPG source..."
  cd $BUILD_DIR/epg
  git checkout package-lock.json
  CHANGED=$(git diff)
  [ -n "$CHANGED" ] && git stash save
  git pull
  [ -n "$CHANGED" ] && git stash apply
fi

echo "Updating npm modules..."
npm update

echo "Preparing directory..."
mkdir -p $OUT_DIR
GUIDE_DIR=$(basename $OUT_DIR)
[ ! -h "${GUIDE_DIR}" ] && ln -s ../${GUIDE_DIR} ${GUIDE_DIR}

echo "Loading EPG api..."
npm run api:load

echo "--- $(date) ---"
for SITE in $SITES; do
  CONN=1
  IFS=':' read -ra ARR <<< "$SITE"
  if [ ${#ARR[@]} -gt 1 ]; then
    SITE=${ARR[0]}
    CONN=${ARR[1]}
  fi
  GUIDE_XML=$GUIDE_DIR/$SITE.xml
  CNT=0
  # build guide use configured language
  for LANG in $LANGS; do
    if [ -f sites/$SITE/${SITE}_$LANG.channels.xml ]; then
      echo "Building guide for $SITE ($LANG)..."
      if [ $CONN -gt 1 ]; then
        npm run grab -- --site=$SITE --lang=$LANG --output=$GUIDE_XML --maxConnections=$CONN 1>~/$SITE.log 2>&1 &
      else
        npm run grab -- --site=$SITE --lang=$LANG --output=$GUIDE_XML 1>~/$SITE.log 2>&1 &
      fi
      watch_completion $SITE ~/$SITE.log &
      CNT=$((CNT+1))
    fi
  done
  # no guide for configured language, use default
  if [ $CNT -eq 0 ]; then
    echo "Building guide for $SITE..."
    if [ $CONN -gt 1 ]; then
      npm run grab -- --site=$SITE --output=$GUIDE_XML --maxConnections=$CONN 1>~/$SITE.log 2>&1 &
    else
      npm run grab -- --site=$SITE --output=$GUIDE_XML 1>~/$SITE.log 2>&1 &
    fi
    watch_completion $SITE ~/$SITE.log &
  fi
done
if [ -f "$(dirname $0)/channels.xml" ]; then
  SITE=curated
  if [ ! -d $SITE ]; then
    mkdir $SITE
    if [ ! -h $SITE/channels.xml ]; then
      ln -s $(dirname $0)/channels.xml $SITE/channels.xml
    fi
  fi
  echo "Building guide for $SITE channels..."
  GUIDE_XML=$GUIDE_DIR/$SITE.xml
  DAYS=${CURATED_DAYS:-2}
  npm run grab -- --channels=$SITE/channels.xml --output=$GUIDE_XML --days=$DAYS 1>~/$SITE.log 2>&1 &
  watch_completion $SITE ~/$SITE.log &
fi

rm -f $LOCK_FILE
