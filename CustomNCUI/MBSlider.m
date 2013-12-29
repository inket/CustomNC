//
//  MBSlider.m
//  CustomNC
//
//  Copyright (c) 2012-2013 Mahdi Bchetnia. Licensed under GNU GPL v3.0. See LICENSE for details.
//

#import "MBSlider.h"

@implementation MBSlider

@synthesize valueLabel = _valueLabel;
@synthesize formatString = _formatString;

- (void)setDoubleValue:(double)aDouble {
    [super setDoubleValue:aDouble];
    [_valueLabel setStringValue:[self formatString]];
}

- (NSString*)stringValue {
    NSString* str = [super stringValue];
    
    if ([str length] > _maxDigits)
        str = [str substringToIndex:_maxDigits];
    
    if ([str hasSuffix:@".0"] || [str hasSuffix:@".00"])
    {
        str = [str stringByReplacingOccurrencesOfString:@".00" withString:@""];
        str = [str stringByReplacingOccurrencesOfString:@".0" withString:@""];
    }
    
    return str;
}

- (NSString*)formatString {
    return [NSString stringWithFormat:_formatString, [self stringValue], [[self stringValue] doubleValue]==1?@"":@"s"];
}

@end
