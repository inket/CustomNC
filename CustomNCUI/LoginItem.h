//
//  loginItem.h
//  Next
//
//  Created by inket on 2/9/11.
//  Copyright 2011 inket. Licensed under GNU GPL v3.0. See LICENSE for details.
//

#import <Cocoa/Cocoa.h>

@interface LoginItem : NSObject {

}

+ (void)addLoginItem;
+ (void)removeLoginItem;
+ (BOOL)loginItemExists;

@end
