//
//  AboutWindowController.m
//  NepTunes
//
//  Created by rurza on 22/02/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "AboutWindowController.h"

@interface AboutWindowController ()
@property (nonatomic) IBOutlet NSTextField *buildLabel;
@property (nonatomic) IBOutlet NSTextField *copyrightLabel;
@property (nonatomic) IBOutlet NSButton *followOnTwitterButton;
@property (nonatomic) IBOutlet NSButton *supportButton;
@property (nonatomic) IBOutlet NSButton *micropixelsButton;
@property (nonatomic) IBOutlet NSButton *rateInMASButton;
@property (nonatomic) IBOutlet NSButton *myLastFmButton;


@end

@implementation AboutWindowController

- (void)windowDidLoad
{
    [super windowDidLoad];
    NSColor *backgroundColor = [NSColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1];
    [self.window.contentView setBackgroundColor:backgroundColor];

    self.window.titlebarAppearsTransparent = YES;
    self.window.titleVisibility = NSWindowTitleHidden;
    NSDictionary *plist = [NSBundle mainBundle].infoDictionary;
    self.buildLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"Version %@ (%@)", nil), [plist objectForKey:@"CFBundleShortVersionString"], [plist objectForKey:@"CFBundleVersion"]];
    self.copyrightLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"%@", nil), [plist objectForKey:@"NSHumanReadableCopyright"]];
    NSColor *elementsColor = [NSColor whiteColor];
    for (NSButton *button in @[self.supportButton, self.followOnTwitterButton, self.rateInMASButton, self.myLastFmButton]) {
        button.wantsLayer = YES;
        button.layer.borderColor = elementsColor.CGColor;
        button.layer.borderWidth = 1;
        button.layer.cornerRadius = 5;
    }
    
    NSMutableParagraphStyle *centredStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [centredStyle setAlignment:NSCenterTextAlignment];
    self.supportButton.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Support", nil)
                                                                         attributes:@{NSForegroundColorAttributeName : elementsColor,
                                                                                      NSParagraphStyleAttributeName: centredStyle}];
    
    self.followOnTwitterButton.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Follow on Twitter", nil)
                                                                                 attributes:@{NSForegroundColorAttributeName : elementsColor,
                                                                                              NSParagraphStyleAttributeName: centredStyle}];
    self.rateInMASButton.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Rate on App Store", nil)
                                                                         attributes:@{NSForegroundColorAttributeName : elementsColor,
                                                                                      NSParagraphStyleAttributeName: centredStyle}];
    
    self.myLastFmButton.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Author's Last.fm", nil)
    attributes:@{NSForegroundColorAttributeName : elementsColor,
                 NSParagraphStyleAttributeName: centredStyle}];

}

- (IBAction)followOnTwitter:(NSButton *)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://twitter.com/rurza"]];
}

- (IBAction)support:(NSButton *)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://micropixels.software/neptunes"]];
}

- (IBAction)openWebsite:(NSButton *)sender {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://micropixels.software"]];
}

- (IBAction)rateInMAS:(NSButton *)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"macappstore://userpub.itunes.apple.com/WebObjects/MZUserPublishing.woa/wa/addUserReview?id=1006739057&type=Purple+Software"]];
}

- (IBAction)openMyLastFm:(NSButton *)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.last.fm/user/rurzynski"]];
}


@end
