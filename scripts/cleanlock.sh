#!/bin/bash

for LOCK in .lock .once .run .wait .curating; do
  [ -f "/build/${LOCK}" ] && {
    echo "Cleaning /build/${LOCK}..."
    rm -f /build/${LOCK}
  }
done