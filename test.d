#!/usr/bin/env dtrace -s
#pragma D option quiet

pid$target:libobjc.A.dylib:class_createInstance:entry
{
  ptr1 = *(long*)copyin(arg0, 8);
  ptr2 = *(long*)copyin((ptr1 + 32) & ~3, 8);
  flags = *(int*)copyin(ptr2, 4);
  ptr3 = (flags & (1 << 31)) || (flags & (1 << 30)) ? *(long*)copyin(ptr2 + 8, 8) : ptr2;
  ptr4 = *(long*)copyin(ptr3 + 24, 8);
  class = copyinstr(ptr4);
  
  @allocations[class] = sum(1);
}

pid$target:libobjc.A.dylib:object_dispose:entry
/arg0 != 0/
{
  printf("HIT\n");
}

/* Don't use objc_destructInstance() which is used to recycle objects */
pid$target:libobjc.A.dylib:object_dispose:entry
/arg0 != 0/
{
  ptr0 = *(long*)copyin(arg0, 8);
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
