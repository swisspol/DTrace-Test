#!/bin/bash -e

CONFIGURATION="Release"
BUILD_DIR="/tmp/TEMP"
PRODUCT="$BUILD_DIR/$CONFIGURATION/TEMP"
TRACE_OUTPUT="/tmp/trace.txt"

# rm -rf "$BUILD_DIR"
# xcodebuild -configuration "$CONFIGURATION" build "SYMROOT=$BUILD_DIR" > /dev/null
# 
# $PRODUCT

sudo rm -f "$TRACE_OUTPUT"
sudo DYLD_SHARED_REGION=avoid dtrace -s "test.d" -o "$TRACE_OUTPUT" -c "$PRODUCT" > /dev/null

echo "=== LEAKS ===="

sort -b "$TRACE_OUTPUT" | while read LINE; do
  if [ "$LINE" != "" ]; then
    CLASS=`echo -n "$LINE" | awk '{ print $1 }'`
    COUNT=`echo -n "$LINE" | awk '{ print $2 }'`
    if [ "$COUNT" != "0" ]; then
      printf "%40s\t%s\n" "$CLASS" "$COUNT"
    fi
  fi
done

echo "======"

echo "Success!"
