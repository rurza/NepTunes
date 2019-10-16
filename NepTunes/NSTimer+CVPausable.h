#import <Foundation/Foundation.h>

@interface NSTimer (CVPausable)

- (void)pauseOrResume;
- (BOOL)isPaused;

@end
