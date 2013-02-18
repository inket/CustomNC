//
//  CNCAppDelegate.h
//  CustomNCUI
//
//  Created by inket on 28/07/2012.
//  Copyright (c) 2012-2013 inket. Licensed under GNU GPL v3.0. See LICENSE for details.
//

#import <Cocoa/Cocoa.h>
#import "MBSlider.h"
#import "LoginItem.h"

@interface CNCAppDelegate : NSObject <NSApplicationDelegate> {
    BOOL isSIMBL;
    BOOL isEasySIMBL;
}

@property (assign) IBOutlet NSWindow *window;

@property (assign) IBOutlet NSButton* alwaysPulseIcon;
@property (assign) IBOutlet NSButton* hideIcon;

@property (assign) IBOutlet NSPopUpButton* entryAnimationStyle;
@property (assign) IBOutlet MBSlider* entryAnimationDuration;

@property (assign) IBOutlet MBSlider* bannerIdleDuration;

@property (assign) IBOutlet NSPopUpButton* exitAnimationStyle;
@property (assign) IBOutlet MBSlider* exitAnimationDuration;

@property (assign) IBOutlet NSButton* fixGrowl;
@property (assign) IBOutlet NSButton* removeAppName;

@property (assign) IBOutlet NSProgressIndicator* progressIndicator;
@property (assign) IBOutlet NSButton* applyButton;

@end
