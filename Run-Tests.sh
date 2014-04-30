#!/bin/bash -ex

CONFIGURATION="Release"

BUILD_DIR="/tmp/TEMP"
PRODUCT="$BUILD_DIR/$CONFIGURATION/TEMP"

rm -rf "$BUILD_DIR"
xcodebuild -configuration "$CONFIGURATION" build "SYMROOT=$BUILD_DIR" > /dev/null

$PRODUCT

echo "Success!"

sudo dtrace -s "test.d" -c "$PRODUCT"
