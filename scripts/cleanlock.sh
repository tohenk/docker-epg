#!/bin/bash

for LOCK in .lock .once; do
  [ -f "/build/$LOCK" ] && {
    echo "Cleaning /build/$LOCK..."
    rm -f /build/$LOCK
  }
done