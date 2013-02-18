//
//  MBSlider.h
//  CustomNC
//
//  Created by inket on 28/07/2012.
//  Copyright (c) 2012-2013 inket. Licensed under GNU GPL v3.0. See LICENSE for details.
//

#import <Cocoa/Cocoa.h>

@interface MBSlider : NSSlider

@property (assign) NSInteger maxDigits;
@property (assign) IBOutlet NSTextField* valueLabel;
@property (assign, nonatomic) NSString* formatString;

- (NSString*)formatString;

@end
