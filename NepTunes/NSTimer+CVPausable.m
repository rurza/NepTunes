#import "NSTimer+CVPausable.h"
#import <objc/runtime.h>

@interface NSTimer (CVPausablePrivate)

@property (nonatomic) NSNumber *timeDeltaNumber;

@end

@implementation NSTimer (CVPausablePrivate)

static void *AssociationKey;

- (NSNumber *)timeDeltaNumber
{
    return objc_getAssociatedObject(self, AssociationKey);
}

- (void)setTimeDeltaNumber:(NSNumber *)timeDeltaNumber
{
    objc_setAssociatedObject(self, AssociationKey, timeDeltaNumber, OBJC_ASSOCIATION_RETAIN);
}

@end


@implementation NSTimer (CVPausable)

- (void)pauseOrResume
{
    if ([self isPaused]) {
        self.fireDate = [[NSDate date] dateByAddingTimeInterval:[self.timeDeltaNumber doubleValue]];
        self.timeDeltaNumber = nil;
    }
    else {
        NSTimeInterval interval = [[self fireDate] timeIntervalSinceNow];
        self.timeDeltaNumber = @(interval);
        self.fireDate = [NSDate distantFuture];
    }
}

- (BOOL)isPaused
{
    return (self.timeDeltaNumber != nil);
}

@end
