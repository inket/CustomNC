//
//  CustomNC.h
//  CustomNC
//
//  Copyright (c) 2012-2013 Mahdi Bchetnia. Licensed under GNU GPL v3.0. See LICENSE for details.
//

#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>
#import <objc/message.h>

// OS X 10.8
#import "NCNotificationWindow.h"
#import "NCWindowLayoutController.h"
#import "NCRoundedWindowContentView.h"
#import "NCAppInfo.h"
#import "NCModel.h"

// OS X 10.9
#import "NCBannerAnimation.h"
#import "NCBannerAnimationVerticalIn.h"
#import "NCBannerAnimationFadeIn.h"
#import "NCBannerAnimationFadeOut.h"
#import "NCBannerAnimationVerticalOut.h"
#import "NCBannerAnimationPoofOut.h"
#import "NCBannerAnimationHorizontalOut.h"
#import "NCBannerWindowController.h"

@interface CustomNC : NSObject

+ (void)set:(id)obj name:(NSString*)name val:(NSNumber*)val;
- (NSImage*)iconForAppName:(NSString *)appName;

@end