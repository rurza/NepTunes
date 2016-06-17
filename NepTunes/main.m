//
//  main.m
//  NepTunes
//
//  Created by rurza on 19.11.2014.
//  Copyright (c) 2014 micropixels. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ReceiptValidation.h"

int main(int argc, const char * argv[]) {
#if DEBUG
    return NSApplicationMain(argc, argv);
#else
    return CheckReceiptAndRun(argc, argv);
#endif
}
