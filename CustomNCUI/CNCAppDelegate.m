//
//  CNCAppDelegate.m
//  CustomNCUI
//
//  Copyright (c) 2012-2014 Mahdi Bchetnia. Licensed under GNU GPL v3.0. See LICENSE for details.
//

#import "CNCAppDelegate.h"

#define RUNNING_AGENT ([NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.github.norio-nomura.SIMBL-Agent"])
#define RUNNING_NC ([NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.notificationcenterui"])

@implementation CNCAppDelegate

#pragma mark - Setting up the UI

- (void)awakeFromNib {
    [_entryAnimationDuration setAltIncrementValue:0.5];
    [_entryAnimationDuration setFormatString:@"%@ second%@"];
    [_bannerIdleDuration setAltIncrementValue:0.5];
    [_bannerIdleDuration setFormatString:@"approx. %@ second%@"];
    [_exitAnimationDuration setAltIncrementValue:0.5];
    [_exitAnimationDuration setFormatString:@"%@ second%@"];
    
    if (![self OSIsMountainLion])
    {
        [_alwaysPulseIcon setState:NSOffState];
        [_alwaysPulseIcon setEnabled:NO];
    }
    
    // Recreate the entry animation styles list, taking into account the OS version
    NSMenu* entryMenu = [[NSMenu alloc] init];
    [entryMenu addItemWithTitle:[self OSIsYosemiteOrHigher] ? @"Slide" : @"Drop" action:nil keyEquivalent:@""];
    [entryMenu addItemWithTitle:@"Fade" action:nil keyEquivalent:@""];
    [_entryAnimationStyle setMenu:entryMenu];
    
    // Recreate the exit animation styles list, taking into account the OS version
    NSMenu* exitMenu = [[NSMenu alloc] init];
    [exitMenu addItemWithTitle:@"Slide" action:nil keyEquivalent:@""];
    [exitMenu addItemWithTitle:@"Fade" action:nil keyEquivalent:@""];
    [exitMenu addItemWithTitle:([self OSIsMavericks] ? @"Raise" : @"Poof") action:nil keyEquivalent:@""];
    [exitMenu addItemWithTitle:@"None" action:nil keyEquivalent:@""];
    [_exitAnimationStyle setMenu:exitMenu];
    
    [self install]; // Install/update plug-in if necessary
    
    if (!isEasySIMBL)
        // SIMBL doesn't inject apps at user login
        // so we have to do that with an automator workflow set as a login item
        [self addLoginItem];
    else
        // EasySIMBL doesn't have such problems
        [self removeLoginItem];
    
    // Sync the UI elements to the saved preferences
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSNumber* entryStyle = [userDefaults objectForKey:@"entryAnimationStyle"];
    [_entryAnimationStyle selectItemAtIndex:entryStyle ? [entryStyle integerValue] : 0];
    
    NSNumber* entryDuration = [userDefaults objectForKey:@"entryAnimationDuration"];
    [_entryAnimationDuration setMaxDigits:4];
    [_entryAnimationDuration setDoubleValue:entryDuration ? [entryDuration doubleValue] : 0.7];

    NSNumber* idleDuration = [userDefaults objectForKey:@"bannerIdleDuration"];
    [_bannerIdleDuration setMaxDigits:3];
    [_bannerIdleDuration setDoubleValue:idleDuration ? [idleDuration doubleValue] : 5];
    
    NSNumber* exitStyle = [userDefaults objectForKey:@"exitAnimationStyle"];
    [_exitAnimationStyle selectItemAtIndex:exitStyle ? [exitStyle integerValue] : 0];
    [self changeExitAnimationStyle:_exitAnimationStyle];
    
    NSNumber* exitDuration = [userDefaults objectForKey:@"exitAnimationDuration"];
    [_exitAnimationDuration setMaxDigits:4];
    [_exitAnimationDuration setDoubleValue:exitDuration ? [exitDuration doubleValue] : 0.6];
    
    BOOL alwaysPulse = [userDefaults boolForKey:@"alwaysPulseIcon"] && [self OSIsMountainLion];
    [_alwaysPulseIcon setState:alwaysPulse ? NSOnState : NSOffState];
    
    [_hideIcon setState:[userDefaults boolForKey:@"hideIcon"] ? NSOnState : NSOffState];
    
    [_fixGrowl setState:[userDefaults boolForKey:@"fixGrowl"] ? NSOnState : NSOffState];
    [self changeGrowlCheckboxValue:_fixGrowl];
    
    [_removeAppName setState:[userDefaults boolForKey:@"removeAppName"] ? NSOnState : NSOffState];
}

#pragma mark - UI Actions/Controls

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    [_window makeKeyAndOrderFront:nil];
    
    return YES;
}

- (void)activate {
    [(NSApplication*)NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)changeGrowlCheckboxValue:(id)sender {
    [_removeAppName setEnabled:[_fixGrowl state]];
    if (![_removeAppName isEnabled]) [_removeAppName setState:NSOffState];
}

- (IBAction)changeSliderValue:(id)sender {
    [[sender valueLabel] setStringValue:[sender formatString]];
}

- (IBAction)changeExitAnimationStyle:(id)sender {
    if ([(NSPopUpButton*)sender indexOfSelectedItem] == 2 && [self OSIsMountainLion]) // Poof animation (in ML) duration can't be changed
    {
        [_exitAnimationDuration setEnabled:NO];
        [_exitAnimationDuration setDoubleValue:0.25];
    }
    else
        [_exitAnimationDuration setEnabled:YES];
}

- (IBAction)defaults:(id)sender {
    [_alwaysPulseIcon setState:NSOffState];
    [_hideIcon setState:NSOffState];
    
    [_entryAnimationStyle selectItemAtIndex:0];
    [_entryAnimationDuration setDoubleValue:0.7];
    
    [_bannerIdleDuration setDoubleValue:5];
    
    [_exitAnimationStyle selectItemAtIndex:0];
    [_exitAnimationDuration setEnabled:YES];
    [_exitAnimationDuration setDoubleValue:0.6];
    
    [_fixGrowl setState:NSOffState];
    [self changeGrowlCheckboxValue:_fixGrowl];
    
    [_removeAppName setState:NSOffState];
}

- (IBAction)uninstall:(id)sender {
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    NSString* pluginsDirectory = [@"~/Library/Application Support/SIMBL/Plugins/" stringByExpandingTildeInPath];
    NSString* destination = [NSString stringWithFormat:@"%@/CustomNC.bundle", pluginsDirectory];
    
    NSError* error = nil;
    [fileManager removeItemAtPath:destination error:&error];
    
    if (error)
        [NSAlert alertWithError:error];
    
    [self removeLoginItem];
    
    NSArray* runningNC = RUNNING_NC;
    
    if ([runningNC count] > 0)
        [(NSRunningApplication*)runningNC[0] terminate];
    
    [fileManager trashItemAtURL:[NSURL URLWithString:[NSString stringWithFormat:@"file://%@", [[NSBundle mainBundle] bundlePath]]] resultingItemURL:nil error:&error];
    
    [NSApp terminate:self];
}

#pragma mark - Applying Settings

- (IBAction)apply:(id)sender {
    if (DEBUG_ENABLED) NSLog(@"%@ user clicked Apply", isEasySIMBL?@"EasySIMBL":@"SIMBL");

    [_applyButton setTitle:@"Applying…"];
    [_applyButton setEnabled:NO];
    
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];

    [userDefaults setBool:[_alwaysPulseIcon state] forKey:@"alwaysPulseIcon"];
    [userDefaults setBool:[_hideIcon state] forKey:@"hideIcon"];

    [userDefaults setInteger:[_entryAnimationStyle indexOfSelectedItem] forKey:@"entryAnimationStyle"];
    [userDefaults setDouble:[[_entryAnimationDuration stringValue] doubleValue] forKey:@"entryAnimationDuration"];
    
    [userDefaults setInteger:[_exitAnimationStyle indexOfSelectedItem] forKey:@"exitAnimationStyle"];
    [userDefaults setDouble:[[_exitAnimationDuration stringValue] doubleValue] forKey:@"exitAnimationDuration"];
    
    [userDefaults setDouble:[[_bannerIdleDuration stringValue] doubleValue] forKey:@"bannerIdleDuration"];

    [userDefaults setBool:[_fixGrowl state] forKey:@"fixGrowl"];
    [userDefaults setBool:[_removeAppName state] forKey:@"removeAppName"];
    
    [userDefaults synchronize];
    
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(updatedSettings:) name:@"CustomNCUpdatedSettings" object:nil];
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"CustomNCUpdateSettings" object:nil];
    
    apply = [NSDate timeIntervalSinceReferenceDate];
    [self performSelector:@selector(NCDidNotRespondToNotification) withObject:nil afterDelay:1.5];
}

- (void)updatedSettings:(NSNotification*)notification {
    [_applyButton setTitle:@"Apply"];
    [_applyButton setEnabled:YES];
    
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:@"CustomNCUpdatedSettings" object:nil];
    
    [self sendNotification];
}

- (void)NCDidNotRespondToNotification {
    if (![_applyButton isEnabled] && ([NSDate timeIntervalSinceReferenceDate] - apply) > 1)
    {
        NSLog(@"NCDidNotRespondToNotification");
        apply = 0;
        
        [_applyButton setTitle:@"Installing…"];
        [_applyButton setEnabled:NO];
        
        [[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:@"CustomNCUpdatedSettings" object:nil];
        
        [self restartNC];
    }
}

#pragma mark - Installing CustomNC's SIMBL plug-in

- (void)install {
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    // *** Making sure SIMBL is installed
    BOOL isDir = NO;
    NSString* SIMBLpath = @"/Library/ScriptingAdditions/SIMBL.osax";
    NSString* SIMBLuserPath = [@"~/Library/ScriptingAdditions/SIMBL.osax" stringByExpandingTildeInPath];
    NSString* easySIMBLpath = [@"~/Library/ScriptingAdditions/EasySIMBL.osax" stringByExpandingTildeInPath];
    
    isSIMBL = [fileManager fileExistsAtPath:SIMBLpath isDirectory:&isDir] || [fileManager fileExistsAtPath:SIMBLuserPath isDirectory:&isDir];
    isEasySIMBL = [fileManager fileExistsAtPath:easySIMBLpath isDirectory:&isDir] || [RUNNING_AGENT count] > 0;
    
    if (DEBUG_ENABLED) NSLog(@"SIMBL: %@, EasySIMBL: %@", isSIMBL?@"YES":@"NO", isEasySIMBL?@"YES":@"NO");
    
    if (!isSIMBL && !isEasySIMBL)
    {
        NSAlert* alert = [NSAlert alertWithMessageText:@"CustomNC requires SIMBL or EasySIMBL to function" defaultButton:@"Take me there!" alternateButton:@"Cancel" otherButton:@"" informativeTextWithFormat:@"SIMBL is a transparent app that enables modifications like CustomNC. It's easy to install and doesn't need any setup.\n\nGet EasySIMBL at https://github.com/norio-nomura/EasySIMBL/#how-to-install"];
        
        NSInteger buttonClicked = [alert runModal];
        
        if (buttonClicked == 1)
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/norio-nomura/EasySIMBL/#how-to-install"]];
        
        [NSApp terminate:self];
    }
    
    // *** Making sure the plugin is in place
    NSString* resourcePath = [[NSBundle mainBundle] resourcePath];
    
    NSString* pluginPath = [NSBundle pathForResource:@"CustomNC" ofType:@"bundle" inDirectory:resourcePath];
    double newPluginVersion = [[[[NSBundle bundleWithPath:pluginPath] infoDictionary] objectForKey:@"CFBundleShortVersionString"] doubleValue];
    
    NSString* pluginsDirectory = [@"~/Library/Application Support/SIMBL/Plugins/" stringByExpandingTildeInPath];
    NSString* destination = [NSString stringWithFormat:@"%@/CustomNC.bundle", pluginsDirectory];
    BOOL isDirectory = NO;
    
    NSBundle* bundle = [NSBundle bundleWithPath:destination];
    double pluginVersion = [[[bundle infoDictionary] objectForKey:@"CFBundleShortVersionString"] doubleValue];
    
    if (!bundle)
    {
        NSError* error = nil;
        
        [fileManager createDirectoryAtPath:pluginsDirectory withIntermediateDirectories:YES attributes:nil error:&error];
        
        if (![fileManager fileExistsAtPath:pluginsDirectory isDirectory:&isDirectory])
        {
            [[NSAlert alertWithError:error] runModal];
            NSLog(@"Couldn't find/create plugins directory @ %@", pluginsDirectory);
            [NSApp terminate:self];
        }
        
        error = nil;
        [fileManager copyItemAtPath:pluginPath toPath:destination error:&error];
        
        if (error)
        {
            [[NSAlert alertWithError:error] runModal];
            NSLog(@"Couldn't install CustomNC SIMBL plugin. Quitting…");
            [NSApp terminate:self];
        }
    }
    else
    {
        BOOL differentVersion = newPluginVersion != pluginVersion;
#ifdef DEBUG
        differentVersion = YES;
#endif
        
        if (differentVersion)
        {
            NSError* error = nil;
            [fileManager removeItemAtPath:destination error:&error];
            
            if (error)
            {
                [[NSAlert alertWithError:error] runModal];
                NSLog(@"Couldn't replace CustomNC plugin @ %@ with a newer version", destination);
                [NSApp terminate:self];
            }
            
            error = nil;
            [fileManager copyItemAtPath:pluginPath toPath:destination error:&error];
            
            if (error)
            {
                [[NSAlert alertWithError:error] runModal];
                NSLog(@"Couldn't install CustomNC SIMBL plugin. Quitting…");
                [NSApp terminate:self];
            }
            
            NSLog(@"Replaced CustomNC plugin with a newer version successfully.");
            [_applyButton setTitle:@"Installing…"];
            [_applyButton setEnabled:NO];
            [self restartNC];
        }
    }
}

#pragma mark - Reinjecting CustomNC

- (void)restartNC {
    NSArray* runningNC = RUNNING_NC;
    
    if ([runningNC count] > 0)
    {
        [(NSRunningApplication*)runningNC[0] terminate];
        if (DEBUG_ENABLED) NSLog(@"Killed NC");
        
        double slept = 0;
        
        while ([RUNNING_NC count] == 0 && slept < 5)
        {
            sleep(1);
            slept += 1;
        }
        
        if ([RUNNING_NC count] == 0)
        {
            NSAlert* alert = [NSAlert alertWithMessageText:@"Uh oh. There seems to be a problem." defaultButton:@"Try later" alternateButton:@"" otherButton:@"" informativeTextWithFormat:@"Notification Center is not running. Please restart and try again."];
            
            [alert runModal];
            
            [NSApp terminate:self];
        }
        else
        {
            [self performSelector:@selector(inject) withObject:nil afterDelay:2];
        }
    }
}

- (void)inject {
    if (isEasySIMBL)
        [self easySIMBLInject];
    else if (isSIMBL)
        [self SIMBLInject];
    
    [_applyButton setTitle:@"Apply"];
    [_applyButton setEnabled:YES];
    
    // Re-activate CustomNC because relaunching NotificationCenter would take focus away
    [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(activate) userInfo:nil repeats:NO];
}

- (void)easySIMBLInject {
    if (DEBUG_ENABLED) NSLog(@"User has EasySIMBL, trying to kill the agent");
    
    NSArray* runningAgent = RUNNING_AGENT;
    
    if ([runningAgent count] > 0)
    {
        NSString* agentPath = [[[(NSRunningApplication*)runningAgent[0] bundleURL] path] copy];
        [(NSRunningApplication*)runningAgent[0] terminate];
        
        if (DEBUG_ENABLED) NSLog(@"Killed the agent @ %@", agentPath);
        
        int slept = 0;
        
        while ([RUNNING_AGENT count] > 0 && slept < 5)
        {
            sleep(1);
            slept += 1;
        }
        
        if ([RUNNING_AGENT count] == 0)
        {
            [[NSWorkspace sharedWorkspace] openFile:agentPath];
            if (DEBUG_ENABLED) NSLog(@"Started the agent");
        }
    }
    else
    {
        NSAlert* alert = [NSAlert alertWithMessageText:@"Uh oh. There seems to be a problem." defaultButton:@"Try later" alternateButton:@"" otherButton:@"" informativeTextWithFormat:@"EasySIMBL's agent is not running. You'll have to restart for the changes to be effective."];
        
        [alert runModal];
    }
}

- (void)SIMBLInject {
    if (DEBUG_ENABLED) NSLog(@"User has SIMBL, trying to start the injector");
    
    NSString* launcherPath = [[NSBundle mainBundle] pathForResource:@"CustomNCLauncher" ofType:@"app"];
    
    [[NSWorkspace sharedWorkspace] openFile:launcherPath];

    if (DEBUG_ENABLED) NSLog(@"Told SIMBL to inject CustomNC");
}

#pragma mark - Sending a Test Notification

- (void)sendNotification {
    NSUserNotification* notification = [[NSUserNotification alloc] init];
    [notification setTitle:@"Settings applied."];
    [notification setSubtitle:@"This is a test notification"];
    
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"HH:mm:ss"];

    NSString* informativeText = [NSString stringWithFormat:@"It's %@ now!", [format stringFromDate:[NSDate date]]];
    [notification setInformativeText:informativeText];
    
    NSUserNotificationCenter* notificationCenter = [NSUserNotificationCenter defaultUserNotificationCenter];
    [notificationCenter setDelegate:(id<NSUserNotificationCenterDelegate>)self];
    [notificationCenter deliverNotification:notification];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
    return YES;
}

#pragma mark - Sending a Growl Test Notification

- (IBAction)sendGrowlNotification:(id)sender {
    NSString* asSource = @"\
    tell application \"System Events\"\n\
    set isRunning to (count of (every process whose bundle identifier is \"com.Growl.GrowlHelperApp\")) > 0\n\
    end tell\n\
    \n\
    if isRunning then\n\
    tell application id \"com.Growl.GrowlHelperApp\"\n\
    set the allNotificationsList to ¬\n\
    {\"Test Notification\"}\n\
    \n\
    set the enabledNotificationsList to ¬\n\
    {\"Test Notification\"}\n\
    \n\
    \n\
    register as application ¬\n\
    \"CustomNC\" all notifications allNotificationsList ¬\n\
    default notifications enabledNotificationsList ¬\n\
    icon of application \"CustomNC\"\n\
    \n\
    \n\
    notify with name ¬\n\
    \"Test Notification\" title ¬\n\
    \"Test Notification\" description ¬\n\
    \"Lorem Ipsum Dolor Sit Amet, Consectetur Adipiscing Elit.\" application name \"CustomNC\"\n\
    \n\
    end tell\n\
    end if";
    
    NSAppleScript* as = [[NSAppleScript alloc] initWithSource:asSource];
    
    NSDictionary* error = nil;
    [as executeAndReturnError:&error];
    
    if (error)
        NSLog(@"%@", error);
}

#pragma mark - Managing the login item to inject at startup
// Applies to SIMBL users only. EasySIMBL users do not need this.

- (void)addLoginItem {
    if (![LoginItem loginItemExists])
        [LoginItem addLoginItem];
}

- (void)removeLoginItem {
    if ([LoginItem loginItemExists])
        [LoginItem removeLoginItem];
}

#pragma mark - Getting the OS version

- (BOOL)OSIsMountainLion {
    return ![NSProcessInfo instancesRespondToSelector:@selector(endActivity:)];
}

- (BOOL)OSIsMavericks {
    return ![self OSIsMountainLion] && ![self OSIsYosemiteOrHigher];
}

- (BOOL)OSIsYosemiteOrHigher {
    return [NSProcessInfo instancesRespondToSelector:@selector(isOperatingSystemAtLeastVersion:)];
}

@end
