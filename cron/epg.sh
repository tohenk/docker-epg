#!/bin/bash

. $(dirname $0)/epg.env
. /config/guides.env

BUILD_DIR=/build
OUT_DIR=$BUILD_DIR/$EPG_GUIDES_DIR
LOCK_FILE=$BUILD_DIR/.lock
RUN_FILE=$BUILD_DIR/.run
ONCE_FILE=$BUILD_DIR/.once
CURATED_FILE=/config/channels.xml

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
  TIMEOUT=$3
  [ -z "$TIMEOUT" ] && TIMEOUT=${WATCH_TIMEOUT:-3600}
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
    DELTA=$(($(date +%s)-$START))
    if [ $DELTA -gt $TIMEOUT ]; then
      break
    fi
  done
}

run_grab() {
  OUT=$1
  SITE=$2
  LANG=$3
  CONN=$4
  DAYS=$5
  POS=$((${#SITE}-4))
  CMD="--output=$OUT"
  if [ "${SITE:$POS:4}" = ".xml" ]; then
    CMD="$CMD --channels=$SITE"
    IFS='/' read -ra AA <<< "$SITE"
    if [ ${#AA[@]} -gt 1 ]; then
      SITE=${AA[0]}
    fi
  else
    CMD="$CMD --site=$SITE"
  fi
  if [ -n "$LANG" -a "x$LANG" != "xNONE" ]; then
    CMD="$CMD --lang=$LANG"
  fi
  if [ -n "$CONN" ]; then
    [ $CONN -gt 1 ] && CMD="$CMD --maxConnections=$CONN"
  fi
  if [ -n "$DAYS" ]; then
    [ $DAYS -gt 0 ] && CMD="$CMD --days=$DAYS"
  fi
  $(echo "npm run grab --- $CMD" | xargs) 1>~/$SITE.log 2>&1 &
  watch_completion $SITE ~/$SITE.log &
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
[ ! -h "$GUIDE_DIR" ] && ln -s ../$GUIDE_DIR $GUIDE_DIR

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
      run_grab $GUIDE_XML $SITE $LANG $CONN
      CNT=$((CNT+1))
    fi
  done
  # no guide for configured language, use default
  if [ $CNT -eq 0 ]; then
    echo "Building guide for $SITE..."
    run_grab $GUIDE_XML $SITE NONE $CONN
  fi
done
if [ -f "$CURATED_FILE" ]; then
  SITE=curated
  CHANNEL=$(basename $CURATED_FILE)
  mkdir -p $SITE
  if [ -h $SITE/$CHANNEL ]; then
    rm -f $SITE/$CHANNEL
  fi
  ln -s $CURATED_FILE $SITE/$CHANNEL
  echo "Building guide for $SITE channels..."
  GUIDE_XML=$GUIDE_DIR/$SITE.xml
  DAYS=${CURATED_DAYS:-2}
  run_grab $GUIDE_XML $SITE/$CHANNEL NONE 1 $DAYS
fi

rm -f $LOCK_FILE
