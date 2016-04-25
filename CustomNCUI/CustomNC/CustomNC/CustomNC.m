//
//  CustomNC.m
//  CustomNC
//
//  Copyright (c) 2012-2016 Mahdi Bchetnia. Licensed under GNU GPL v3.0. See LICENSE for details.
//

#import "CustomNC.h"

static CustomNC* plugin = nil;
static BOOL customNCInstalled = NO;
static NSImage* currentAppIcon = nil;

static BOOL hideIcon = NO;
static BOOL alwaysPulseIcon = NO;
static BOOL fixGrowl = NO;
static BOOL removeAppName = YES;
static double entryAnimationDuration = 0.7;
static NSInteger entryAnimationStyle = 0;
static double exitAnimationDuration = 0.6;
static NSInteger exitAnimationStyle = 0;
static double bannerIdleDuration = 5;

@implementation NSObject (CustomNC)

#pragma mark - Entry animation

#pragma mark -- OS X 10.9+

// Entry animation style
+ (id)new_animationInWithWindow:(id)arg1 delegate:(id)arg2 animation:(int)arg3 {
    // CustomNCUI on 10.9: 0 = Drop, 1 = Fade, 2 = None
    // CustomNCUI on 10.10: 0 = Slide, 1 = Fade, 2 = None
    // NotificationCenter 10.9: 0 = None, 1 = invalid, 2 = FadeIn, 3 = None, 4 = None, 5 = VerticalIn
    // NotificationCenter 10.10: 0 = invalid, 1 = invalid, 2 = FadeIn, 3 = invalid, 4 = invalid, 5 = HorizontalIn
    
    int style = arg3;
    switch (entryAnimationStyle) {
        case 0: style = 5; break;
        case 1: style = 2; break;
    }
    
    return [self new_animationInWithWindow:arg1 delegate:arg2 animation:style];
}

#pragma mark - Idle duration

#pragma mark -- OS X 10.10+

// Banner idle duration
- (void)new__displayNotification:(id)arg1 forApplication:(id)arg2 withUnpresentedCount:(unsigned long long)arg3 animation:(int)arg4 {
    if (!customNCInstalled)
    {
        [CustomNC set:self name:@"_bannerTime" val:[NSNumber numberWithDouble:bannerIdleDuration+entryAnimationDuration]];
        customNCInstalled = YES;
    }
    
    [self new__displayNotification:arg1 forApplication:arg2 withUnpresentedCount:arg3 animation:4];
}

#pragma mark - Exit animation

#pragma mark -- OS X 10.10+

// Exit animation style
+ (id)new_animationOutWithWindow:(id)arg1 delegate:(id)arg2 animation:(int)style {
    // CustomNCUI on 10.10: 0 = Slide, 1 = Fade, 2 = Poof, 3 = None
    // NotificationCenter 10.10: 0 = None, 1 = invalid, 2 = FadeOut, 3 = invalid, 4 = PoofOut, 5 = HorizontalOut
    
    switch (exitAnimationStyle) {
        case 0: style = 5; break;
        case 1: style = 2; break;
        case 2: style = 4; break;
        case 3: style = 0; break;
    }
    
    return [self new_animationOutWithWindow:arg1 delegate:arg2 animation:style];
}

#pragma mark - Hiding icon

#pragma mark -- OS X 10.10+

// Hiding the icon
- (BOOL)new_updateBodyWidthConstraint {
    BOOL result = [self new_updateBodyWidthConstraint];

    if (!hideIcon) return result;

    NSView* bodyTFContainer = ((NSTextField*)[self performSelector:@selector(bodyTF)]).superview;
    NSView* scrollView = bodyTFContainer.superview.superview;
    NSView* underMasterView = scrollView.superview;
    NSView* masterView = scrollView.superview.superview;

    // Reduce scrollView's left margin from 46 to 8
    NSLayoutConstraint* constraintToRemove = nil;
    for (NSLayoutConstraint* constraint in masterView.constraints) {
        if (constraint.firstItem == scrollView)
        {
            constraintToRemove = constraint;
            break;
        }
    }
    [masterView removeConstraint:constraintToRemove];

    NSArray* constraintsToAdd = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(8)-[scrollView]"
                                                                        options:0
                                                                        metrics:nil
                                                                          views:@{@"|": masterView, @"scrollView": scrollView}];
    [masterView addConstraints:constraintsToAdd];


    // Replace the notification title's constraint
    for (NSView* subview in underMasterView.subviews) {
        if ([subview isKindOfClass:NSClassFromString(@"NCFadedClipView")])
        {
            NSView* fadedClipView = subview;
            NSArray* newConstraint = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(11)-[NCFadedClipView]"
                                                                             options:0
                                                                             metrics:nil
                                                                               views:@{@"|": underMasterView, @"NCFadedClipView": fadedClipView}];
            [underMasterView addConstraints:newConstraint];

            break;
        }
    }

    for (NSView* subview in masterView.subviews) {
        if ([subview isKindOfClass:NSClassFromString(@"NCIdentityImageView")])
        {
            // Resize the icon to 0x0 using constraints
            NSImageView* identity = (NSImageView*)subview;
            [identity removeConstraints:[identity constraints]];
            NSDictionary* views = @{@"image": identity};
            [identity addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[image(0)]" options:0 metrics:nil views:views]];
            [identity addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[image(0)]" options:0 metrics:nil views:views]];
            break;
        }
    }

    return result;
}

#pragma mark -- OS X 10.9+

- (void)new__setHorizontalMask {
    [self new__setHorizontalMask];
    
    // Overwrite width with a hardcoded value :(
    if (hideIcon)
        [(NSView*)self setFrameSize:NSMakeSize(292, ((NSView*)self).frame.size.height)];
}

#pragma mark - OS X 10.9+ Banner animations duration

// Entry animation duration + Exit animation duration
- (id)new_initWithWindow:(id)arg1 type:(int)arg2 delegate:(id)arg3 duration:(double)arg4 transitionType:(int)arg5 {
    id result = nil;
    
    if (arg5 == 1) // Entry animation
        result = [self new_initWithWindow:arg1 type:arg2 delegate:arg3 duration:entryAnimationDuration transitionType:arg5];
    else // Exit animation
        result = [self new_initWithWindow:arg1 type:arg2 delegate:arg3 duration:exitAnimationDuration transitionType:arg5];
    
    return result;
}

#pragma mark - Fixing Growl

// Show app icon in Notification Center instead of Growl's and optionally remove the app name
- (void)new_setNote:(NSUserNotification*)note {
    if (fixGrowl)
    {
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
    }
    
    [self new_setNote:note];
}

@end

@implementation CustomNC

#pragma mark - SIMBL methods and loading

+ (CustomNC*)sharedInstance {
	if (plugin == nil)
		plugin = [[CustomNC alloc] init];
	
	return plugin;
}

+ (void)load {
	[[CustomNC sharedInstance] loadPlugin];
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(gotNewSettings:) name:@"CustomNCUpdateSettings" object:nil];
	
	NSLog(@"CustomNC loaded.");
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"CustomNCInjected" object:nil];
}

+ (void)set:(id)obj name:(NSString*)name val:(NSNumber*)val {
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
}

- (void)loadPlugin {
    [self reloadValues];
    [self swizzle];
}

- (void)reloadValues {
    NSDictionary* userDefaults = [[[NSUserDefaults alloc] init] persistentDomainForName:@"me.inket.CustomNC"];

    // Notification icon settings
    alwaysPulseIcon = [userDefaults objectForKey:@"alwaysPulseIcon"]?[[userDefaults objectForKey:@"alwaysPulseIcon"] boolValue]:NO;
    hideIcon = [userDefaults objectForKey:@"hideIcon"]?[[userDefaults objectForKey:@"hideIcon"] boolValue]:NO;
    
    // Notification entry animation settings
    entryAnimationStyle = [userDefaults objectForKey:@"entryAnimationStyle"]?[[userDefaults objectForKey:@"entryAnimationStyle"] integerValue]:0;
    entryAnimationDuration = [userDefaults objectForKey:@"entryAnimationDuration"]?[[userDefaults objectForKey:@"entryAnimationDuration"] doubleValue]:0.7;
    if (entryAnimationDuration == 0)
        entryAnimationDuration = 0.001;
    
    // Notification idle settings
    bannerIdleDuration = [userDefaults objectForKey:@"bannerIdleDuration"]?[[userDefaults objectForKey:@"bannerIdleDuration"] doubleValue]:5;
    
    // Notification exit animation settings
    exitAnimationStyle = [userDefaults objectForKey:@"exitAnimationStyle"]?[[userDefaults objectForKey:@"exitAnimationStyle"] integerValue]:0;
    exitAnimationDuration = [userDefaults objectForKey:@"exitAnimationDuration"]?[[userDefaults objectForKey:@"exitAnimationDuration"] doubleValue]:0.6;
    if (exitAnimationDuration == 0)
        exitAnimationDuration = 0.001;
    
    // Growl notifications settings
    fixGrowl = [userDefaults objectForKey:@"fixGrowl"]?[[userDefaults objectForKey:@"fixGrowl"] boolValue]:NO;
    removeAppName = [userDefaults objectForKey:@"removeAppName"]?[[userDefaults objectForKey:@"removeAppName"] boolValue]:NO;
    
    customNCInstalled = NO;
}

- (void)swizzle {
    // Fixing Growl
    [self swizzle:NSClassFromString(@"NCModel") method:@selector(setNote:)];
    
    Class class = NSClassFromString(@"NCBannerAnimation");
    
    // Entry animation style
    [self swizzle:class classMethod:@selector(animationInWithWindow:delegate:animation:)];

    // Exit animation style
    [self swizzle:class classMethod:@selector(animationOutWithWindow:delegate:animation:)];
    
    // Entry animation duration + Exit animation duration
    [self swizzle:class method:@selector(initWithWindow:type:delegate:duration:transitionType:)];
    
    // Banner idle duration
    [self swizzle:NSClassFromString(@"NCWindowLayoutController")
          method:@selector(_displayNotification:forApplication:withUnpresentedCount:animation:)];
    
    // Hiding the icon
    [self swizzle:NSClassFromString(@"NCBannerViewController") method:@selector(updateBodyWidthConstraint)];

    [self swizzle:NSClassFromString(@"NCAlertScrollView") method:@selector(_setHorizontalMask)];
}

- (void)swizzle:(Class)class method:(SEL)oldSelector prefix:(NSString*)prefix {
    SEL newSelector = NSSelectorFromString([NSString stringWithFormat:@"new_%@_%@", prefix, NSStringFromSelector(oldSelector)]);
    
    Method new = class_getInstanceMethod(class, newSelector);
    Method old = class_getInstanceMethod(class, oldSelector);
    
    method_exchangeImplementations(old, new);
}

- (void)swizzle:(Class)class method:(SEL)oldSelector {
    SEL newSelector = NSSelectorFromString([NSString stringWithFormat:@"new_%@", NSStringFromSelector(oldSelector)]);
    
    Method new = class_getInstanceMethod(class, newSelector);
	Method old = class_getInstanceMethod(class, oldSelector);
    
    method_exchangeImplementations(old, new);
}

- (void)swizzle:(Class)class classMethod:(SEL)oldSelector prefix:(NSString*)prefix {
    SEL newSelector = NSSelectorFromString([NSString stringWithFormat:@"new_%@_%@", prefix, NSStringFromSelector(oldSelector)]);
    
    Method new = class_getClassMethod(class, newSelector);
    Method old = class_getClassMethod(class, oldSelector);
    
    method_exchangeImplementations(old, new);
}

- (void)swizzle:(Class)class classMethod:(SEL)oldSelector {
    SEL newSelector = NSSelectorFromString([NSString stringWithFormat:@"new_%@", NSStringFromSelector(oldSelector)]);

    Method new = class_getClassMethod(class, newSelector);
	Method old = class_getClassMethod(class, oldSelector);
    
    method_exchangeImplementations(old, new);
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

+ (void)gotNewSettings:(NSNotification*)notification {
    [[self sharedInstance] reloadValues];
    NSLog(@"Updated CustomNC settings.");
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"CustomNCUpdatedSettings" object:nil];
}

@end

