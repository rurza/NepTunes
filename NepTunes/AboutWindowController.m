//
//  AboutWindowController.m
//  NepTunes
//
//  Created by rurza on 22/02/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "AboutWindowController.h"

@interface AboutWindowController ()
@property (strong) IBOutlet NSTextField *buildLabel;
@property (strong) IBOutlet NSTextField *copyrightLabel;
@property (strong) IBOutlet NSButton *followOnTwitterButton;
@property (strong) IBOutlet NSButton *supportButton;

@end

@implementation AboutWindowController

- (void)windowDidLoad
{
    [super windowDidLoad];
    NSColor *backgroundColor = [NSColor colorWithRed:0.074 green:0.113 blue:0.18 alpha:1];
    [self.window.contentView setBackgroundColor:backgroundColor];
    //[NSColor colorWithRed:0.941 green:0.968 blue:1 alpha:1]];
    //    [self.window.contentView setBackgroundColor:[NSColor whiteColor]];

    self.window.titlebarAppearsTransparent = YES;
    self.window.titleVisibility = NSWindowTitleHidden;
    NSDictionary *plist = [NSBundle mainBundle].infoDictionary;
    self.buildLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"Version %@ (%@)", nil), [plist objectForKey:@"CFBundleShortVersionString"], [plist objectForKey:@"CFBundleVersion"]];
    self.copyrightLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"%@", nil), [plist objectForKey:@"NSHumanReadableCopyright"]];

    for (NSButton *button in @[self.supportButton, self.followOnTwitterButton]) {
        [button.cell setBackgroundColor:backgroundColor];
        button.wantsLayer = YES;
        button.layer.borderColor = [NSColor colorWithRed:0.941 green:0.968 blue:1 alpha:1].CGColor;
        button.layer.borderWidth = 1;
        button.layer.cornerRadius = 3;
    }
    NSMutableParagraphStyle *centredStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [centredStyle setAlignment:NSCenterTextAlignment];
    self.supportButton.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Support", nil)
                                                                         attributes:@{NSForegroundColorAttributeName : [NSColor colorWithRed:0.941 green:0.968 blue:1 alpha:1],
                                                                                      NSParagraphStyleAttributeName: centredStyle}];
    
    self.followOnTwitterButton.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Follow on Twitter", nil)
                                                                                 attributes:@{NSForegroundColorAttributeName : [NSColor colorWithRed:0.941 green:0.968 blue:1 alpha:1],
                                                                                              NSParagraphStyleAttributeName: centredStyle}];

}

- (IBAction)followOnTwitter:(NSButton *)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://twitter.com/neptunesformac"]];
}

- (IBAction)support:(NSButton *)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://micropixels.pl/neptunes/#faq"]];
}
@end
