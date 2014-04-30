#import <Foundation/Foundation.h>

#if __LP64__
typedef uint32_t mask_t;
#   define MASK_SHIFT ((mask_t)0)
#else
typedef uint16_t mask_t;
#   define MASK_SHIFT ((mask_t)0)
#endif

struct cache_t {
  struct bucket_t *buckets;
  mask_t shiftmask;
  mask_t occupied;
};

struct class_ro_t {
  uint32_t flags;
  uint32_t instanceStart;
  uint32_t instanceSize;
#ifdef __LP64__
  uint32_t reserved;
#endif
  
  const void * ivarLayout;
  
  const char * name;
  const void * baseMethods;
  const void * baseProtocols;
  const void * ivars;
  
  const void * weakIvarLayout;
  const void *baseProperties;
};

struct class_rw_t {
  uint32_t flags;
  uint32_t version;
  
  const class_ro_t *ro;
  
  union {
    void **method_lists;
    void *method_list;
  };
  void *properties;
  const void ** protocols;
  
  void* firstSubclass;
  void* nextSiblingClass;
};

struct _objc_object {
private:
  uintptr_t isa;
};

struct _objc_class : _objc_object {
  void* superclass;
  cache_t cache;
  uintptr_t data_NEVER_USE;
};

@interface TEMP : NSObject
@end

@implementation TEMP
@end

#define RW_REALIZED (1<<31)
#define RW_FUTURE (1<<30)
#define CLASS_FAST_FLAG_MASK  3
#define TAG_MASK 1
#define TAG_SLOT_SHIFT 0
#define TAG_SLOT_MASK 0xf

extern "C" Class objc_debug_taggedpointer_classes[];  // Available in 10.9 for tagged pointers decoding

static const char* ClassNameFromInstance(id instance) {
  char* ptr0 = (char*)instance;
  
  char* ptr1;
  if ((long)ptr0 & TAG_MASK) {
    long slot = ((long)ptr0 >> TAG_SLOT_SHIFT) & TAG_SLOT_MASK;
    ptr1 = (char*)objc_debug_taggedpointer_classes[slot];  // struct objc_class pointer
  } else {
    ptr1 = *(char**)ptr0;  // struct objc_class pointer i.e. instance ISA
  }
  
  char* ptr2 = *((char**)(((long)ptr1 + 32) & ~CLASS_FAST_FLAG_MASK));  // struct class_ro_t or struct class_rw_t pointer
  
  uint32_t flags = *((uint32_t*)ptr2);  // struct class_ro_t or struct class_rw_t flags
  char* ptr3;
  if ((flags & RW_REALIZED) || (flags & RW_FUTURE)) {
    ptr3 = *((char**)((long)ptr2 + 8));  // struct class_ro_t pointer from struct class_rw_t pointer
  } else {
    ptr3 = ptr2;  // struct class_ro_t pointer same as struct class_rw_t pointer
  }
  
  const char* name = *((char**)((long)ptr3 + 24));  // Name string pointer from struct class_ro_t pointer
  
  return name;
}

int main(int argc, const char * argv[]) {
  fprintf(stdout, "objc_debug_taggedpointer_classes = %p\n", objc_debug_taggedpointer_classes);
  
  _objc_class temp1;
  fprintf(stdout, "%lu\n", (long)&temp1.data_NEVER_USE - (long)&temp1);
  
  class_rw_t temp2;
  fprintf(stdout, "%lu\n", (long)&temp2.ro - (long)&temp2);
  
  class_ro_t temp3;
  fprintf(stdout, "%lu\n", (long)&temp3.name - (long)&temp3);
  
  id test;
  
  test = [[TEMP alloc] init];
  fprintf(stdout, "%s = %p\n", ClassNameFromInstance(test), test);
  [test release];
  
  test = [[NSNumber alloc] initWithInt:1];
  fprintf(stdout, "%s = %p\n", ClassNameFromInstance(test), test);
  [test release];
  
  return 0;
}
