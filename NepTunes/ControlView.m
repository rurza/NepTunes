//
//  ControlView.m
//  NepTunes
//
//  Created by rurza on 20/02/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "ControlView.h"

@implementation ControlView

-(void)rotateWithEvent:(NSEvent *)event
{
    NSLog(@"=== rotate: %@ ===", event);
}

-(void)magnifyWithEvent:(NSEvent *)event
{
    NSLog(@"magnify: %@", event);
}

-(BOOL)wantsScrollEventsForSwipeTrackingOnAxis:(NSEventGestureAxis)axis
{
    return YES;
}

-(void)mouseDown:(NSEvent *)theEvent
{
    NSLog(@"mouseDown: %@", theEvent);
}

-(BOOL)acceptsFirstResponder
{
    return YES;
}

@end
