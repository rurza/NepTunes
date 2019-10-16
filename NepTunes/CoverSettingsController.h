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

typedef NS_ENUM(NSInteger, CoverSize) {
    CoverSizeSmall = 1,
    CoverSizeMedium,
    CoverSizeLarge
};

@interface CoverSettingsController : NSObject

@property (nonatomic) BOOL showCover;
@property (nonatomic) CoverPosition coverPosition;
@property (nonatomic) CoverSize coverSize;
@property (nonatomic) BOOL ignoreMissionControl;
@property (nonatomic) BOOL bringiTunesToFrontWithDoubleClick;

@property (nonatomic) BOOL simpleMode;
@property (nonatomic) BOOL notificationMode;


@property (nonatomic) IBOutlet NSButton *albumCoverCheckbox;
@property (nonatomic) IBOutlet NSPopUpButton *albumCoverPosition;
@property (nonatomic) IBOutlet NSButton *ignoreMissionControlCheckbox;
@property (nonatomic) IBOutlet NSButton *bringiTunesToFrontWithDoubleClickCheckbox;
@property (nonatomic) IBOutlet NSPopUpButton *coverSizePopUp;

@property (nonatomic) IBOutlet NSButton *simpleModeCheckbox;
@property (nonatomic) IBOutlet NSButton *notificationModeCheckbox;

+ (instancetype)sharedCoverSettings;
- (void)updateAlbumPosition:(CoverPosition)position;



@end
