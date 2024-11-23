#!/bin/bash

for LOCK in .lock .once .run; do
  [ -f "/build/$LOCK" ] && {
    echo "Cleaning /build/$LOCK..."
    rm -f /build/$LOCK
  }
done