#!/bin/bash -e

CONFIGURATION="Release"
BUILD_DIR="/tmp/TEMP"
PRODUCT="$BUILD_DIR/$CONFIGURATION/TEMP"
TRACE_SCRIPT="/tmp/trace.d"
TRACE_OUTPUT="/tmp/trace.txt"

DTRACE_SCRIPT='

#!/usr/bin/env dtrace -s
#pragma D option quiet

pid$target:libobjc.A.dylib:class_createInstance:entry
{
  ptr0 = arg0;
  ptr1 = *(long*)copyin(ptr0, 8);
  ptr2 = *(long*)copyin((ptr1 + 32) & ~3, 8);
  flags = *(int*)copyin(ptr2, 4);
  ptr3 = (flags & (1 << 31)) || (flags & (1 << 30)) ? *(long*)copyin(ptr2 + 8, 8) : ptr2;
  ptr4 = *(long*)copyin(ptr3 + 24, 8);
  class = copyinstr(ptr4);
  
  @allocations[class] = sum(1);
}

/* Do not use objc_destructInstance() which is used to recycle objects */
pid$target:libobjc.A.dylib:object_dispose:entry
/arg0 != 0/
{
  ptr0 = *(long*)copyin(arg0, 8);  /* TODO: Getting ISA from object this way will not work for tagged pointers but they likely do not get disposed of anyway */
  ptr1 = *(long*)copyin(ptr0, 8);
  ptr2 = *(long*)copyin((ptr1 + 32) & ~3, 8);
  ptr3 = (flags & (1 << 31)) || (flags & (1 << 30)) ? *(long*)copyin(ptr2 + 8, 8) : ptr2;
  ptr4 = *(long*)copyin(ptr3 + 24, 8);
  class = copyinstr(ptr4);
  
  @allocations[class] = sum(-1);
}

END
{
  printa(@allocations);
}

'

rm -rf "$BUILD_DIR"
xcodebuild -configuration "$CONFIGURATION" build "SYMROOT=$BUILD_DIR" > /dev/null

$PRODUCT

sudo rm -f "$TRACE_SCRIPT" "$TRACE_OUTPUT"
echo "$DTRACE_SCRIPT" > "$TRACE_SCRIPT"
sudo DYLD_SHARED_REGION=avoid dtrace -s "$TRACE_SCRIPT" -o "$TRACE_OUTPUT" -c "$PRODUCT" > /dev/null

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
