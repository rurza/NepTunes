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
@property (nonatomic) BOOL bringiTunesToFrontWithDoubleClick;

@property (nonatomic) IBOutlet NSButton *albumCoverCheckbox;
@property (nonatomic) IBOutlet NSPopUpButton *albumCoverPosition;
@property (nonatomic) IBOutlet NSButton *ignoreMissionControlCheckbox;
@property (nonatomic) IBOutlet NSButton *bringiTunesToFrontWithDoubleClickCheckbox;

@end