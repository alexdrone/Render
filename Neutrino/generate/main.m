#import <Foundation/Foundation.h>
#import "generate-Swift.h"

int main(int argc, const char * argv[]) {
  @autoreleasepool {
    NSMutableArray<NSString *> *arguments = @[].mutableCopy;
    for (NSUInteger i = 0; i < argc; i++) {
      NSString *arg = [[NSString alloc] initWithUTF8String:argv[i]];
      [arguments addObject:arg];
    }
    Generator *generator = [[Generator alloc] init];
    [generator run];
  }
  return 0;
}
