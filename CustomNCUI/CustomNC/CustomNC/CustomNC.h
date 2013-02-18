//
//  CustomNC.h
//  CustomNC
//
//  Created by inket on 26/07/2012.
//  Copyright (c) 2012-2013 inket. Licensed under GNU GPL v3.0. See LICENSE for details.
//

#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import "NCNotificationWindow.h"
#import "NCWindowLayoutController.h"
#import "NCRoundedWindowContentView.h"
#import "NCAppInfo.h"
#import "NCModel.h"

@interface CustomNC : NSObject

+ (void)set:(id)obj name:(NSString*)name val:(NSNumber*)val;
- (NSImage*)iconForAppName:(NSString *)appName;

@end