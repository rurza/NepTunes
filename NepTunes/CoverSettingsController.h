//
//  CoverSettingsController.h
//  NepTunes
//
//  Created by rurza on 18/02/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "SettingsController.h"

typedef NS_ENUM(NSInteger, CoverPosition) {
    CoverPositionStuckToTheDesktop = 1,
    CoverPositionAboveAllOtherWindows,
    CoverPositionMixedInWithOtherWindows
};

@interface CoverSettingsController : NSObject

@property (nonatomic) BOOL showCover;
@property (nonatomic) CoverPosition coverPosition;
@property (nonatomic) BOOL ignoreMissionControl;

@property (strong) IBOutlet NSButton *albumCoverCheckbox;
@property (strong) IBOutlet NSPopUpButton *albumCoverPosition;
@property (strong) IBOutlet NSButton *ignoreMissionControlCheckbox;

@end
