//
//  MBSlider.h
//  CustomNC
//
//  Copyright (c) 2012-2014 Mahdi Bchetnia. Licensed under GNU GPL v3.0. See LICENSE for details.
//

#import <Cocoa/Cocoa.h>

@interface MBSlider : NSSlider

@property (assign) NSInteger maxDigits;
@property (assign) IBOutlet NSTextField* valueLabel;
@property (assign, nonatomic) NSString* formatString;

- (NSString*)formatString;

@end
