//
//  CustomNC.m
//  CustomNC
//
//  Created by inket on 26/07/2012.
//  Copyright (c) 2012-2013 inket. Licensed under GNU GPL v3.0. See LICENSE for details.
//

#import "CustomNC.h"

static CustomNC* plugin = nil;
static BOOL customNCInstalled = NO;
static NSDate* date = nil;
static NSDate* date2 = nil;
static NSDate* date3 = nil;
static NSImage* currentAppIcon = nil;

static BOOL alwaysPulseIcon = NO;
static BOOL removeAppName = YES;
static double entryAnimationDuration = 0.7;
static NSInteger entryAnimationStyle = 0;
static double exitAnimationDuration = 0.6;
static NSInteger exitAnimationStyle = 0;
static double bannerIdleDuration = 5;

@implementation NSObject (CustomNC)

#pragma mark Debug methods
// *** Debug methods
- (void)new_windowAnimateOutStart {
    double timePassed_ms = [date2 timeIntervalSinceNow] * -1000.0;
	NSLog(@"Stayed for: %f", timePassed_ms);
    date3 = [NSDate date];
    
    [self new_windowAnimateOutStart];
}

- (void)new_windowAnimateOutComplete {
    double timePassed_ms = [date3 timeIntervalSinceNow] * -1000.0;
	NSLog(@"Out animation duration: %f", timePassed_ms);
    
    [self new_windowAnimateOutComplete];
}

- (void)new_windowAnimateInComplete {
    double timePassed_ms = [date timeIntervalSinceNow] * -1000.0;
    NSLog(@"In animation duration: %lf", timePassed_ms);
    date2 = [NSDate date];
    
    [self new_windowAnimateInComplete];
}

#pragma mark Entry animation
// Entry animation style, duration and icon pulse
- (void)new_animateInDrop:(id)arg1 duration:(double)arg2 {
//    date = [NSDate date];
    
    switch (entryAnimationStyle) {
        case 1: [(NCWindowLayoutController*)self animateInFade:arg1 duration:entryAnimationDuration]; break;
        default: [self new_animateInDrop:arg1 duration:entryAnimationDuration]; break;
    }
    
    if (alwaysPulseIcon) [arg1 pulseIcon];
}

#pragma mark Idle duration
// Changing the value for the banner idle duration
- (void)new__presentBanner:(id)arg1 withUnpresentedCount:(unsigned long long)arg2 {
    if (!customNCInstalled)
    {
        [CustomNC set:self name:@"_bannerTime" val:[NSNumber numberWithDouble:bannerIdleDuration+entryAnimationDuration]];
        customNCInstalled = YES;
    }
    
    [self new__presentBanner:arg1 withUnpresentedCount:arg2];
}

#pragma mark Exit animation
// Exit animation style and duration
- (void)new_animateOutSlide:(id)arg1 duration:(double)arg2 {
    switch (exitAnimationStyle) {
        case 1: [(NCWindowLayoutController*)self animateOutFade:arg1 duration:exitAnimationDuration]; break;
        case 2: [(NCWindowLayoutController*)self _animateAlertOff:arg1 poof:YES slide:NO]; break;
        default: [self new_animateOutSlide:arg1 duration:exitAnimationDuration]; break;
    }
}

#pragma mark Hiding icon
// Hiding the icon
- (void)new_loadView {
    [self new_loadView];
    
    // Get the elements inside the notification
    NSTextField* bodyTF = (NSTextField*)[self performSelector:@selector(bodyTF)];
    NSTextField* headerTF = (NSTextField*)[self performSelector:@selector(headerTF)];
    NSTextField* subtitleTF = (NSTextField*)[self performSelector:@selector(subtitleTF)];
    NSImageView* theView = (NSImageView*)[self performSelector:@selector(imageView)];
    
    // Remove the conflicting horizontal constraints
    NSArray* t = [[theView superview] constraints];
    
    for (int i=0; i<[t count]; i++)
    {
        if (([[(NSLayoutConstraint*)t[i] firstItem] isEqualTo:bodyTF]
             || [[(NSLayoutConstraint*)t[i] firstItem] isEqualTo:headerTF]
             || [[(NSLayoutConstraint*)t[i] firstItem] isEqualTo:subtitleTF])
            && [[(NSLayoutConstraint*)t[i] description] rangeOfString:@"H:"].location != NSNotFound)
        {
            [[theView superview] removeConstraint:t[i]];
        }
    }
    
    // Add new constraints for the text
    NSDictionary* views = @{ @"|" : [theView superview], @"body": bodyTF, @"title": headerTF, @"subtitle": subtitleTF };
    NSMutableArray* newConstraints = [NSMutableArray array];
    [newConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(12)-[body]" options:0 metrics:nil views:views]];
    [newConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(12)-[subtitle]" options:0 metrics:nil views:views]];
    [newConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(12)-[title]" options:0 metrics:nil views:views]];
    [[theView superview] addConstraints:newConstraints];
    
    // Replace size constraints for the image view
    [theView removeConstraints:[theView constraints]];
    views = [NSDictionary dictionaryWithObject:theView forKey:@"image"];
    [theView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[image(0)]" options:0 metrics:nil views:views]];
    [theView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[image(0)]" options:0 metrics:nil views:views]];
}


#pragma mark Fixing Growl
// Show app icon in Notification Center instead of Growl's and optionally remove the app name
- (void)new_setNote:(NSUserNotification*)note {
    if ([[[self performSelector:@selector(app)] performSelector:@selector(bundleIdentifier)] isEqualToString:@"com.Growl.GrowlHelperApp"]
        && (!removeAppName || !([[note subtitle] isEqualToString:@""])))
    {
        NSString* appName = [note title];
        NSImage* newIcon = [plugin iconForAppName:appName];
        NCAppInfo* app = [self performSelector:@selector(app)];
        
        NSString* varName = @"_image";
        currentAppIcon = newIcon;
        object_setIvar(app,
                       class_getInstanceVariable([app class], [varName cStringUsingEncoding:NSUTF8StringEncoding]),
                       currentAppIcon);
        
        if (removeAppName)
        {
            [note setTitle:[note subtitle]];
            [note setSubtitle:@""];
        }
    }
    
    [self new_setNote:note];
}

@end

@implementation CustomNC

#pragma mark SIMBL methods and loading

+ (CustomNC*)sharedInstance {
	if (plugin == nil)
		plugin = [[CustomNC alloc] init];
	
	return plugin;
}

+ (void)load {
	[[CustomNC sharedInstance] loadPlugin];
	
	NSLog(@"CustomNC loaded.");
}

+ (void)set:(id)obj name:(NSString*)name val:(NSNumber*)val {
    // Getting
    id result = object_getIvar(obj, class_getInstanceVariable([obj class], [name cStringUsingEncoding:NSUTF8StringEncoding]));    
    
    // Sanitize val for __NSTaggedDate (only accepts integers passed as double)
    NSString* stringVal = [val stringValue];
    double value = 5;
    if ([stringVal length] > 3)
        stringVal = [stringVal substringToIndex:3];
    
    value = [stringVal doubleValue];
    NSInteger tmp = [stringVal integerValue];
    if (value-tmp < 0.5)
        value = (double)tmp;
    else
        value = (double)tmp+1;

    // Needed object
    id r = objc_msgSend(NSClassFromString(@"__NSTaggedDate"), @selector(__new:), (double)value);
    
    // Setting
    object_setIvar(obj, class_getInstanceVariable([obj class], [name cStringUsingEncoding:NSUTF8StringEncoding]), r);

    // Checking
    result = object_getIvar(obj, class_getInstanceVariable([obj class], [name cStringUsingEncoding:NSUTF8StringEncoding]));
//    NSLog(@"%@", result); // Debug
}

- (void)loadPlugin {
    
    // *** Getting the values
    
    NSDictionary* userDefaults = [[[NSUserDefaults alloc] init] persistentDomainForName:@"me.inket.CustomNC"];
    alwaysPulseIcon = [userDefaults objectForKey:@"alwaysPulseIcon"]?[[userDefaults objectForKey:@"alwaysPulseIcon"] boolValue]:NO;
    BOOL hideIcon = [userDefaults objectForKey:@"hideIcon"]?[[userDefaults objectForKey:@"hideIcon"] boolValue]:NO;
    
    BOOL fixGrowl = [userDefaults objectForKey:@"fixGrowl"]?[[userDefaults objectForKey:@"fixGrowl"] boolValue]:NO;
    removeAppName = [userDefaults objectForKey:@"removeAppName"]?[[userDefaults objectForKey:@"removeAppName"] boolValue]:NO;
    
    entryAnimationStyle = [userDefaults objectForKey:@"entryAnimationStyle"]?[[userDefaults objectForKey:@"entryAnimationStyle"] integerValue]:0;
    
    BOOL alterEntryAnimationStyle = entryAnimationStyle == 0 ? NO : YES;
    
    
    entryAnimationDuration = [userDefaults objectForKey:@"entryAnimationDuration"]?[[userDefaults objectForKey:@"entryAnimationDuration"] doubleValue]:0.7;
    
    if (entryAnimationDuration == 0)
        entryAnimationDuration = 0.001;
    
    BOOL alterEntryAnimationDuration = entryAnimationDuration == 0.7 ? NO : YES;
    

    exitAnimationStyle = [userDefaults objectForKey:@"exitAnimationStyle"]?[[userDefaults objectForKey:@"exitAnimationStyle"] integerValue]:0;
    
    BOOL alterExitAnimationStyle = exitAnimationStyle == 0 ? NO : YES;
    
    
    exitAnimationDuration = [userDefaults objectForKey:@"exitAnimationDuration"]?[[userDefaults objectForKey:@"exitAnimationDuration"] doubleValue]:0.6;
    
    if (exitAnimationDuration == 0)
        exitAnimationDuration = 0.001;
    
    BOOL alterExitAnimationDuration = exitAnimationDuration == 0.6 ? NO : YES;
    
    
    bannerIdleDuration = [userDefaults objectForKey:@"bannerIdleDuration"]?[[userDefaults objectForKey:@"bannerIdleDuration"] doubleValue]:5;
    
    BOOL alterBannerIdleDuration = bannerIdleDuration == 5 ? NO : YES;
    
    
    // *** Start the swizzling
    
	Class class = NSClassFromString(@"NCNotificationWindow");

    // Debug
//    [self swizzle:class method:@selector(windowAnimateOutStart)];
//    [self swizzle:class method:@selector(windowAnimateOutComplete)];
//    [self swizzle:class method:@selector(windowAnimateInComplete)];
    
    if (fixGrowl)
    {
        class = NSClassFromString(@"NCModel");
        [self swizzle:class method:@selector(setNote:)];
    }
    
    class = NSClassFromString(@"NCWindowLayoutController");
    
    if (alterExitAnimationDuration || alterExitAnimationStyle)
        [self swizzle:class method:@selector(animateOutSlide:duration:)];
    
    if (alwaysPulseIcon || alterEntryAnimationDuration || alterEntryAnimationStyle)
        [self swizzle:class method:@selector(animateInDrop:duration:)];
    
    if (alterBannerIdleDuration)
        [self swizzle:class method:@selector(_presentBanner:withUnpresentedCount:)];
    
    if (hideIcon)
    {
        class = NSClassFromString(@"NCBannerViewController");
        [self swizzle:class method:@selector(loadView)];
    }
}

- (void)swizzle:(Class)class method:(SEL)oldSelector {
    SEL newSelector = NSSelectorFromString([NSString stringWithFormat:@"new_%@", NSStringFromSelector(oldSelector)]);
    
    Method new = class_getInstanceMethod(class, newSelector);
	Method old = class_getInstanceMethod(class, oldSelector);
    
    method_exchangeImplementations(new, old);
}

- (NSImage*)iconForAppName:(NSString *)appName {
    NSWorkspace* workspace = [NSWorkspace sharedWorkspace];
    
    NSString* appPath = [workspace fullPathForApplication:appName];
    
    if (!appPath)
        // Fallback to Growl's icon for network notifications
        appPath = [[workspace URLForApplicationWithBundleIdentifier:@"com.Growl.GrowlHelperApp"] path];
    
    NSImage* icon = [workspace iconForFile:appPath];
    return icon ? icon : nil;
}

@end

